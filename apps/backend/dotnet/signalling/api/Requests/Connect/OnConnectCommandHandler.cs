using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Text.Json;
using Amazon.Lambda.APIGatewayEvents;
using Flyingdarts.DynamoDb.Service;
using Flyingdarts.Lambda.Core.Infrastructure;
using Flyingdarts.Meetings.Service.Services;
using Flyingdarts.Persistence;
using MediatR;

namespace Flyingdarts.Backend.Signalling.Api.Requests.Connect;

public class OnConnectCommandHandler : IRequestHandler<OnConnectCommand, APIGatewayProxyResponse>
{
    private readonly IMeetingService _meetingService;
    private readonly IDynamoDbService _dynamoDbService;

    public OnConnectCommandHandler(IMeetingService meetingService, IDynamoDbService dynamoDbService)
    {
        _meetingService = meetingService;
        _dynamoDbService = dynamoDbService;
    }

    public async Task<APIGatewayProxyResponse> Handle(
        OnConnectCommand request,
        CancellationToken cancellationToken
    )
    {
        try
        {
            var user = await EnsureUserIsUpdatedOrCreated(request, cancellationToken);

            user.MeetingIdentifier = await EnsureUserHasMeetingRoom(user, cancellationToken);

            await _dynamoDbService.WriteUserAsync(user, cancellationToken);

            var body = new Dictionary<string, string>
            {
                { "UserId", user.UserId },
                { "MeetingIdentifier", user.MeetingIdentifier.ToString() },
            };

            return ResponseBuilder.SuccessJson(body, 201);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[OnConnect] Error during connection process for AuthProviderUserId: {request.AuthProviderUserId}. Error: {ex.Message}"
            );
            Console.WriteLine($"[OnConnect] Stack trace: {ex.StackTrace}");
            throw;
        }
    }

    private async Task<User> EnsureUserIsUpdatedOrCreated(
        OnConnectCommand request,
        CancellationToken cancellationToken
    )
    {
        User? user = null;
        try
        {
            user = await _dynamoDbService.ReadUserByAuthProviderUserIdAsync(
                request.AuthProviderUserId,
                cancellationToken
            );
        }
        catch (DynamoDbService.UserNotFoundException)
        {
            var userProfile = CreateFromAuthressToken(
                request.AuthressToken,
                request.IsServiceClient
            );

            user = User.Create(request.AuthProviderUserId, request.ConnectionId, userProfile);

            await _dynamoDbService.WriteUserAsync(user, cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[OnConnect] Unexpected error while ensuring user for AuthProviderUserId: {request.AuthProviderUserId}. Error: {ex.Message}"
            );
            throw;
        }
        finally
        {
            if (user is null)
            {
                Console.WriteLine(
                    $"[OnConnect] User is null after all attempts for AuthProviderUserId: {request.AuthProviderUserId}"
                );
                throw new Exception("User not found");
            }
        }
        return user;
    }

    private UserProfile CreateFromAuthressToken(string token, bool isServiceClient = false)
    {
        try
        {
            if (string.IsNullOrEmpty(token))
            {
                throw new Exception("Token is null or empty");
            }

            if (isServiceClient)
            {
                return GetServiceClientUserProfile(token);
            }

            var normalizedToken = NormalizeAuthressToken(token);
            // Parse the JWT token to extract user information
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(normalizedToken);

            var userProfile = new UserProfile();

            // Example: Extract "name" and "email" claims if they exist
            var nameClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "name");
            if (nameClaim != null)
            {
                userProfile.UserName = nameClaim.Value;
            }
            else { }

            var emailClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "email");
            if (emailClaim != null)
            {
                userProfile.Email = emailClaim.Value;
            }
            else { }

            var pictureClaim = jwtToken.Claims.FirstOrDefault(c => c.Type == "picture");
            if (pictureClaim != null)
            {
                userProfile.Picture = pictureClaim.Value;
            }
            else { }

            return userProfile;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[OnConnect] Error creating user profile from token: {ex.Message}");
            throw;
        }
    }

    public UserProfile GetServiceClientUserProfile(string token)
    {
        try
        {
            var idToken = token.Split('.')[1];

            // JWT tokens use Base64URL encoding, need to convert to standard Base64
            var base64String = idToken.Replace('-', '+').Replace('_', '/');

            // Add padding if needed
            switch (base64String.Length % 4)
            {
                case 2:
                    base64String += "==";
                    break;
                case 3:
                    base64String += "=";
                    break;
            }

            var base64Decoded = Convert.FromBase64String(base64String);
            var jsonPayload = JsonSerializer.Deserialize<Dictionary<string, object>>(base64Decoded);

            return new UserProfile
            {
                UserName = jsonPayload?["sub"]?.ToString() ?? "unknown",
                Email = "mike+test@flyingdarts.net",
                Country = "NL",
                Picture =
                    "https://i.postimg.cc/HnD0HyQM/male-face-icon-default-profile-image-c3f2c592f9.jpg", // expires in 31 days
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[OnConnect] Error decoding JWT token: {ex.Message}");
            Console.WriteLine(
                $"[OnConnect] Token part being decoded: {(token?.Split('.').Length > 1 ? token.Split('.')[1] : "INVALID_TOKEN")}"
            );

            // Return a fallback profile or rethrow based on your requirements
            throw new InvalidOperationException($"Failed to decode JWT token: {ex.Message}", ex);
        }
    }

    private static string NormalizeAuthressToken(string authressToken)
    {
        if (string.IsNullOrWhiteSpace(authressToken))
        {
            return string.Empty;
        }

        // Normalize leading/trailing whitespace first
        var trimmedToken = authressToken.Trim();

        const string userPrefix = "user=";

        // Case 1: Token starts with "user=" (case-insensitive)
        if (trimmedToken.StartsWith(userPrefix, StringComparison.OrdinalIgnoreCase))
        {
            var tokenValue = trimmedToken.Substring(userPrefix.Length).Trim();
            return tokenValue;
        }

        return trimmedToken;
    }

    private async Task<Guid> EnsureUserHasMeetingRoom(
        User user,
        CancellationToken cancellationToken
    )
    {
        try
        {
            var meeting = await _meetingService.GetByNameAsync(user.UserId, cancellationToken);

            if (meeting is null)
            {
                meeting = await _meetingService.CreateAsync(user.UserId, cancellationToken);

                if (meeting is null)
                {
                    throw new Exception("Couldn't create or find a meeting for some reason");
                }

                if (meeting.Id is null)
                {
                    throw new Exception(
                        $"Couldn't add the meeting because the id was null {JsonSerializer.Serialize(meeting)}"
                    );
                }

                await _dynamoDbService.WriteUserAsync(user, cancellationToken);
            }
            else { }

            var meetingId = meeting.Id ?? throw new Exception("Cant add user id");
            return meetingId;
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[OnConnect] Error ensuring meeting room for UserId: {user.UserId}. Error: {ex.Message}"
            );
            throw;
        }
    }
}
