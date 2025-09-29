using Amazon.Lambda.APIGatewayEvents;
using Flyingdarts.DynamoDb.Service;
using Flyingdarts.Lambda.Core.Infrastructure;
using MediatR;

namespace Flyingdarts.Backend.Signalling.Api.Requests.Disconnect;

public class OnDisconnectCommandHandler
    : IRequestHandler<OnDisconnectCommand, APIGatewayProxyResponse>
{
    private readonly IDynamoDbService _dynamoDbService;

    public OnDisconnectCommandHandler(IDynamoDbService dynamoDbService)
    {
        _dynamoDbService = dynamoDbService;
    }

    public async Task<APIGatewayProxyResponse> Handle(
        OnDisconnectCommand request,
        CancellationToken cancellationToken
    )
    {
        try
        {
            // Find user by connection ID
            var user = await _dynamoDbService.ReadUserByConnectionIdAsync(
                request.ConnectionId ?? string.Empty,
                cancellationToken
            );

            if (user != null)
            {
                // Remove the connection ID
                user.ConnectionId = string.Empty;
                await _dynamoDbService.WriteUserAsync(user, cancellationToken);
            }
            else { }

            return ResponseBuilder.SuccessJson(new { message = "Disconnected." }, 200);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[OnDisconnect] Error during disconnect process for ConnectionId: {request.ConnectionId}. Error: {ex.Message}"
            );
            Console.WriteLine($"[OnDisconnect] Stack trace: {ex.StackTrace}");
            throw;
        }
    }
}
