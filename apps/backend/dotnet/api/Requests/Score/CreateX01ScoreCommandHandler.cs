using System.Text;
using System.Text.Json;
using Amazon.ApiGatewayManagementApi;
using Amazon.ApiGatewayManagementApi.Model;
using Amazon.Lambda.APIGatewayEvents;
using Flyingdarts.Connection.Services;
using Flyingdarts.Core.Models;
using Flyingdarts.DynamoDb.Service;
using Flyingdarts.Metadata.Services.Services.X01;
using Flyingdarts.Persistence;
using MediatR;

namespace Flyingdarts.Backend.Api.Requests.Score;

public record CreateX01ScoreCommandHandler(
    IDynamoDbService DynamoDbService,
    IAmazonApiGatewayManagementApi ApiGatewayClient,
    CachingService<X01State> CachingService,
    X01MetadataService MetadataService,
    ConnectionService ConnectionService
) : IRequestHandler<CreateX01ScoreCommand, APIGatewayProxyResponse>
{
    public async Task<APIGatewayProxyResponse> Handle(
        CreateX01ScoreCommand request,
        CancellationToken cancellationToken
    )
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(request.GameId);
        ArgumentNullException.ThrowIfNull(request.ConnectionId);

        var socketMessage = new SocketMessage<CreateX01ScoreCommand> { Action = "games/x01/score" };

        var playerId = await GetPlayerIdAsync(request.PlayerId, cancellationToken);
        // Update connection ID
        await ConnectionService.UpdateConnectionIdAsync(
            playerId,
            request.ConnectionId,
            cancellationToken
        );

        // Load game state
        await CachingService.Load(request.GameId, cancellationToken);

        // Create and save dart record
        await CreateDartRecordAsync(request, playerId, cancellationToken);

        // Check if game is finished and update accordingly
        await HandleGameCompletionAsync(request.GameId, playerId, cancellationToken);

        // Populate metadata as the final step
        var metadata = await MetadataService.GetMetadataAsync(
            request.GameId,
            playerId,
            cancellationToken
        );

        socketMessage.Metadata = metadata.ToDictionary();

        // Get all player connection IDs
        var gameUsers = CachingService.State?.Users ?? new List<User>();
        var playerConnectionIds = gameUsers
            .Select(x => x.ConnectionId)
            .Where(id => !string.IsNullOrEmpty(id))
            .ToArray();

        // Notify people in the room
        await NotifyRoomAsync(socketMessage, playerConnectionIds, cancellationToken);

        return new APIGatewayProxyResponse
        {
            StatusCode = 200,
            Body = JsonSerializer.Serialize(socketMessage),
        };
    }

    private async Task<string> GetPlayerIdAsync(
        string authProviderUserId,
        CancellationToken cancellationToken
    )
    {
        var user = await DynamoDbService.ReadUserByAuthProviderUserIdAsync(
            authProviderUserId,
            cancellationToken
        );
        return user.UserId;
    }

    private async Task CreateDartRecordAsync(
        CreateX01ScoreCommand request,
        string playerId,
        CancellationToken cancellationToken
    )
    {
        var setsAndLegs = GetSetsAndLegs();

        if (setsAndLegs is null)
        {
            return;
        }

        var gameDart = GameDart.Create(
            long.Parse(request.GameId),
            playerId,
            request.Input,
            request.Score,
            setsAndLegs.Value.Set,
            setsAndLegs.Value.Leg
        );

        // Write dart to database and cache
        try
        {
            await DynamoDbService.WriteGameDartAsync(gameDart, cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] CreateDartRecordAsync - Failed to write dart to database: {ex.Message}"
            );
            Console.WriteLine($"[ERROR] CreateDartRecordAsync - Exception details: {ex}");
            throw;
        }

        try
        {
            CachingService.AddDart(gameDart);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] CreateDartRecordAsync - Failed to add dart to cache: {ex.Message}"
            );
            Console.WriteLine($"[ERROR] CreateDartRecordAsync - Exception details: {ex}");
            throw;
        }

        try
        {
            await CachingService.Save(cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] CreateDartRecordAsync - Failed to save cache: {ex.Message}"
            );
            Console.WriteLine($"[ERROR] CreateDartRecordAsync - Exception details: {ex}");
            throw;
        }
    }

    private async Task HandleGameCompletionAsync(
        string gameId,
        string playerId,
        CancellationToken cancellationToken
    )
    {
        var metadata = await MetadataService.GetMetadataAsync(gameId, playerId, cancellationToken);

        if (metadata.WinningPlayer is not null)
        {
            var game = (
                await DynamoDbService.ReadStartedGameAsync(long.Parse(gameId), cancellationToken)
            ).Single();
            game.Status = GameStatus.Finished;

            // Write game to database and cache
            await DynamoDbService.WriteGameAsync(game, cancellationToken);
            CachingService.AddGame(game);
            await CachingService.Save(cancellationToken);
        }
    }

    private (int Set, int Leg)? GetSetsAndLegs()
    {
        var darts = CachingService.State?.Darts ?? new List<GameDart>();

        if (darts is { Count: 0 })
        {
            return (1, 1);
        }

        int currentSet = 1;
        int currentLeg = 1;
        var x01 = CachingService.State?.Game?.X01;
        int legsNeededToWinSet = ((x01?.Legs ?? 1) + 1) / 2;

        // Track leg wins per player per set
        var legWinsPerPlayer = new Dictionary<string, int>();

        var safeDarts = darts ?? Enumerable.Empty<GameDart>();
        foreach (var dart in safeDarts)
        {
            if (dart is null)
            {
                continue;
            }
            legWinsPerPlayer.TryGetValue(dart.PlayerId, out var currentWins);

            // Check if the player has won the leg
            if (dart.GameScore == 0)
            {
                legWinsPerPlayer[dart.PlayerId] = currentWins + 1;

                // Check if the player has won enough legs to win the set
                if (legWinsPerPlayer[dart.PlayerId] >= legsNeededToWinSet)
                {
                    currentSet++;
                    currentLeg = 1; // Reset leg count for the new set

                    // Reset leg wins for all players for the new set
                    legWinsPerPlayer.Clear();
                }
                else
                {
                    currentLeg++; // Move to the next leg within the same set
                }
            }
        }

        return (currentSet, currentLeg);
    }

    private async Task NotifyRoomAsync(
        SocketMessage<CreateX01ScoreCommand> socketMessage,
        string[] connectionIds,
        CancellationToken cancellationToken
    )
    {
        if (connectionIds.Length == 0)
        {
            return;
        }

        var messageJson = JsonSerializer.Serialize(socketMessage);
        var messageBytes = Encoding.UTF8.GetBytes(messageJson);

        var tasks = connectionIds
            .Select(async connectionId =>
            {
                var stream = new MemoryStream(messageBytes);
                var postConnectionRequest = new PostToConnectionRequest
                {
                    ConnectionId = connectionId,
                    Data = stream,
                };

                try
                {
                    await ApiGatewayClient.PostToConnectionAsync(
                        postConnectionRequest,
                        cancellationToken
                    );
                }
                catch (GoneException)
                {
                    // Connection is no longer available, ignore
                }
                catch (Exception ex)
                {
                    Console.WriteLine(
                        $"[ERROR] NotifyRoomAsync - Failed to send message to connection {connectionId}: {ex.Message}"
                    );
                }
            })
            .ToArray();

        await Task.WhenAll(tasks);
    }
}
