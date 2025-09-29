// Import statements are organized and simplified

// Create a serializer for JSON serialization and deserialization

using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Authress.SDK;
using Authress.SDK.Client;

var serializer = new DefaultLambdaJsonSerializer(x => x.PropertyNameCaseInsensitive = true);

// Define the Lambda function handler
var handler = async (APIGatewayCustomAuthorizerRequest apiGatewayEvent, ILambdaContext context) =>
{
    string? ExtractToken()
    {
        if (string.IsNullOrEmpty(apiGatewayEvent.RequestContext?.ConnectionId))
        {
            var authHeader =
                apiGatewayEvent.Headers?.ContainsKey("Authorization") == true
                    ? apiGatewayEvent.Headers["Authorization"]
                    : null;

            if (string.IsNullOrEmpty(authHeader))
            {
                return null;
            }

            // Remove "Bearer " prefix if present
            var token = authHeader.StartsWith("Bearer ") ? authHeader.Substring(7) : authHeader;
            return token;
        }

        var queryToken =
            apiGatewayEvent.QueryStringParameters?.ContainsKey("token") == true
                ? apiGatewayEvent.QueryStringParameters["token"]
                : null;

        if (string.IsNullOrEmpty(queryToken))
        {
            return null;
        }

        return queryToken;
    }

    async Task<string> ValidateToken(string token)
    {
        if (string.IsNullOrEmpty(token))
        {
            throw new ArgumentException("Token cannot be null or empty");
        }

        try
        {
            var authressApiUrl = Environment.GetEnvironmentVariable("AuthressApiBasePath");

            if (string.IsNullOrEmpty(authressApiUrl))
            {
                throw new InvalidOperationException(
                    "AuthressApiUrl environment variable is not set"
                );
            }

            var authressSettings = new AuthressSettings { AuthressApiUrl = authressApiUrl };

            var tokenProvider = new ManualTokenProvider();
            tokenProvider.SetToken(token);

            var authressClient = new AuthressClient(tokenProvider, authressSettings);

            var authressIdentity = await authressClient.VerifyToken(token);

            return authressIdentity.UserId;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[AUTH] ERROR during token validation: {ex.Message}");
            Console.WriteLine($"[AUTH] Exception type: {ex.GetType().Name}");
            Console.WriteLine($"[AUTH] Stack trace: {ex.StackTrace}");
            throw;
        }
    }

    try
    {
        var token = ExtractToken();
        if (string.IsNullOrEmpty(token))
        {
            Console.WriteLine($"[AUTH] ERROR: Failed to extract token");
            return new APIGatewayCustomAuthorizerResponse
            {
                PrincipalID = "401",
                PolicyDocument = new APIGatewayCustomAuthorizerPolicy
                {
                    Statement = new List<APIGatewayCustomAuthorizerPolicy.IAMPolicyStatement>
                    {
                        new()
                        {
                            Effect = "Deny",
                            Resource = new HashSet<string> { apiGatewayEvent.MethodArn },
                            Action = new HashSet<string> { "execute-api:Invoke" },
                        },
                    },
                },
            };
        }

        var userId = await ValidateToken(token);
        var connectionId = apiGatewayEvent.RequestContext?.ConnectionId;

        return new APIGatewayCustomAuthorizerResponse
        {
            PrincipalID = userId,
            PolicyDocument = new APIGatewayCustomAuthorizerPolicy
            {
                Statement = new List<APIGatewayCustomAuthorizerPolicy.IAMPolicyStatement>
                {
                    new()
                    {
                        Effect = "Allow",
                        Resource = new HashSet<string> { "*" },
                        Action = new HashSet<string> { "execute-api:Invoke" },
                    },
                },
            },
            Context = new APIGatewayCustomAuthorizerContextOutput
            {
                { "UserId", userId },
                { "ConnectionId", connectionId ?? string.Empty },
            },
        };
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[AUTH] ERROR during authorization: {ex.Message}");
        Console.WriteLine($"[AUTH] Exception type: {ex.GetType().Name}");
        Console.WriteLine($"[AUTH] Stack trace: {ex.StackTrace}");
        Console.WriteLine($"[AUTH] Returning 401 response");

        return new APIGatewayCustomAuthorizerResponse
        {
            PrincipalID = "401",
            PolicyDocument = new APIGatewayCustomAuthorizerPolicy
            {
                Statement = new List<APIGatewayCustomAuthorizerPolicy.IAMPolicyStatement>
                {
                    new()
                    {
                        Effect = "Deny",
                        Resource = new HashSet<string> { apiGatewayEvent.MethodArn },
                        Action = new HashSet<string> { "execute-api:Invoke" },
                    },
                },
            },
        };
    }
};

// Create and run the Lambda function (kept as per your original structure)
await LambdaBootstrapBuilder.Create(handler, serializer).Build().RunAsync();
