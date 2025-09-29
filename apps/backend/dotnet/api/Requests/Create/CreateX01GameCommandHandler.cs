using System.Text.Json;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.APIGatewayEvents;
using Flyingdarts.Connection.Services;
using Flyingdarts.Core.Models;
using Flyingdarts.DynamoDb.Service;
using Flyingdarts.Meetings.Service.Services;
using Flyingdarts.Metadata.Services.Services.X01;
using Flyingdarts.Persistence;
using MediatR;

namespace Flyingdarts.Backend.Api.Requests.Create;

record CreateGameRequest(int Sets, int Legs, int PlayerCount, Guid MeetingIdentifier);

public record CreateX01GameCommandHandler(
    IDynamoDBContext DbContext,
    CachingService<X01State> CachingService,
    ConnectionService ConnectionService,
    IDynamoDbService DynamoDbService,
    IMeetingService MeetingService,
    X01MetadataService MetadataService
) : IRequestHandler<CreateX01GameCommand, APIGatewayProxyResponse>
{
    public async Task<APIGatewayProxyResponse> Handle(
        CreateX01GameCommand request,
        CancellationToken cancellationToken
    )
    {
        try
        {
            ArgumentNullException.ThrowIfNull(request);
            ArgumentNullException.ThrowIfNull(request.ConnectionId);

            var socketMessage = new SocketMessage<CreateX01GameCommand>
            {
                Action = "games/x01/create",
            };

            var playerId = await GetPlayerIdAsync(request.PlayerId, cancellationToken);

            // Update connection ID
            await ConnectionService.UpdateConnectionIdAsync(
                playerId,
                request.ConnectionId,
                cancellationToken
            );

            var gameCreator = await DynamoDbService.ReadUserAsync(playerId, cancellationToken);

            var createGameRequest = new CreateGameRequest(
                request.Sets,
                request.Legs,
                request.PlayerCount,
                gameCreator.MeetingIdentifier
            );

            var game = await CreateGameAsync(createGameRequest, cancellationToken);

            // Populate metadata as the final step
            var metadata = await MetadataService.GetMetadataAsync(
                game.GameId.ToString(),
                playerId,
                cancellationToken
            );
            socketMessage.Metadata = metadata.ToDictionary();

            var response = new APIGatewayProxyResponse
            {
                StatusCode = 200,
                Body = JsonSerializer.Serialize(socketMessage),
            };

            return response;
        }
        catch (ArgumentNullException ex)
        {
            Console.WriteLine(
                $"[ERROR] Invalid request parameters in CreateX01GameCommandHandler.Handle: {ex.Message}"
            );
            throw;
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] Unexpected error in CreateX01GameCommandHandler.Handle for PlayerId: {request.PlayerId}. Error: {ex.Message}"
            );
            throw;
        }
    }

    private async Task<string> GetPlayerIdAsync(
        string authProviderUserId,
        CancellationToken cancellationToken
    )
    {
        try
        {
            var user = await DynamoDbService.ReadUserByAuthProviderUserIdAsync(
                authProviderUserId,
                cancellationToken
            );

            return user.UserId;
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] Failed to get player ID for auth provider user ID: {authProviderUserId}. Error: {ex.Message}"
            );
            throw;
        }
    }

    private async Task<Game> CreateGameAsync(
        CreateGameRequest request,
        CancellationToken cancellationToken
    )
    {
        try
        {
            var game = Game.Create(
                request.PlayerCount,
                X01GameSettings.Create(request.Sets, request.Legs),
                request.MeetingIdentifier
            );

            // Initialize cache state
            CachingService.State = X01State.Create(game.GameId);
            CachingService.AddGame(game);
            await CachingService.Save(cancellationToken);

            // Write to database
            await DynamoDbService.WriteGameAsync(game, cancellationToken);

            return game;
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] Failed to create game with meeting: {request.MeetingIdentifier}. Error: {ex.Message}"
            );
            throw;
        }
    }

    private static DynamoDBOperationConfig GetOperationConfig() =>
        new()
        {
            OverrideTableName =
                $"Flyingdarts-Application-Table-{Environment.GetEnvironmentVariable("EnvironmentName")}",
        };
}
