using System.Text;
using System.Text.Json;
using Amazon.ApiGatewayManagementApi;
using Amazon.ApiGatewayManagementApi.Model;
using Amazon.Lambda.APIGatewayEvents;
using Flyingdarts.Connection.Services;
using Flyingdarts.Core.Models;
using Flyingdarts.DynamoDb.Service;
using Flyingdarts.Meetings.Service.Services;
using Flyingdarts.Meetings.Service.Services.DyteMeetingService.Requests;
using Flyingdarts.Metadata.Services.Services.X01;
using Flyingdarts.Persistence;
using MediatR;

namespace Flyingdarts.Backend.Api.Requests.Join;

public record JoinX01GameCommandHandler( //
    IAmazonApiGatewayManagementApi ApiGatewayClient,
    CachingService<X01State> CachingService,
    ConnectionService ConnectionService,
    IDynamoDbService DynamoDbService,
    IMeetingService MeetingService,
    X01MetadataService MetadataService
) : IRequestHandler<JoinX01GameCommand, APIGatewayProxyResponse>
{
    public async Task<APIGatewayProxyResponse> Handle(
        JoinX01GameCommand request,
        CancellationToken cancellationToken
    )
    {
        ArgumentNullException.ThrowIfNull(request);
        ArgumentNullException.ThrowIfNull(request.GameId);
        ArgumentNullException.ThrowIfNull(request.ConnectionId);

        var socketMessage = new SocketMessage<JoinX01GameCommand> { Action = "games/x01/join" };

        var playerId = await GetPlayerIdAsync(request.PlayerId, cancellationToken);

        // Update connection ID
        await ConnectionService.UpdateConnectionIdAsync(
            playerId,
            request.ConnectionId,
            cancellationToken
        );

        // Load game state
        await CachingService.Load(request.GameId, cancellationToken);

        // Update user connection ID in cache
        await UpdateUserConnectionIdAsync(playerId, request.ConnectionId, cancellationToken);

        // Keep track of game in request
        request.Game = CachingService.State.Game;

        // Add player to game if not already present
        await AddPlayerToGameAsync(request, playerId, cancellationToken);

        // Start game if we have 2 players
        await StartGameIfReadyAsync(request, cancellationToken);

        var gameIdForMetadata = request.Game?.GameId ?? throw new Exception("GameId is required");
        var metadata = await MetadataService.GetMetadataAsync(
            gameIdForMetadata.ToString(),
            playerId,
            cancellationToken
        );

        // Populate metadata as the final step
        socketMessage.Metadata = metadata.ToDictionary();

        // // Get all player connection IDs
        var gameUsers = CachingService.State?.Users ?? new List<User>();
        var playerConnectionIds = gameUsers
            .Select(x => x.ConnectionId)
            .Where(id => !string.IsNullOrEmpty(id))
            .ToArray();

        // Notify people in the room

        // If its just the owner of the message, don't notify
        if (playerConnectionIds.Any(x => x != socketMessage.ConnectionId))
        {
            var connectionsWithoutMessageOwner = playerConnectionIds.Where(x =>
                x != socketMessage.ConnectionId
            );

            await NotifyRoomAsync(
                socketMessage,
                connectionsWithoutMessageOwner.ToArray(),
                cancellationToken
            );

            var notifiedCount = playerConnectionIds.Any(x => x != socketMessage.ConnectionId)
                ? playerConnectionIds.Where(x => x != socketMessage.ConnectionId).Count()
                : 0;
        }

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

    private async Task NotifyRoomAsync(
        SocketMessage<JoinX01GameCommand> request,
        string[] connectionIds,
        CancellationToken cancellationToken
    )
    {
        var stream = new MemoryStream(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(request)));

        foreach (var connectionId in connectionIds)
        {
            if (string.IsNullOrEmpty(connectionId))
                continue;

            var postConnectionRequest = new PostToConnectionRequest
            {
                ConnectionId = connectionId,
                Data = stream,
            };

            stream.Position = 0;
            await ApiGatewayClient.PostToConnectionAsync(postConnectionRequest, cancellationToken);
        }
    }

    private async Task UpdateUserConnectionIdAsync(
        string playerId,
        string connectionId,
        CancellationToken cancellationToken
    )
    {
        var existingUser = CachingService.State.Users.FirstOrDefault(x => x.UserId == playerId);
        if (existingUser is not null)
        {
            existingUser.ConnectionId = connectionId;
            await CachingService.Save(cancellationToken);
        }
        else { }
    }

    private async Task AddPlayerToGameAsync(
        JoinX01GameCommand request,
        string playerId,
        CancellationToken cancellationToken
    )
    {
        // If player is already in the game, do nothing
        if (CachingService.State.Players.Any(x => x.PlayerId == playerId))
        {
            return;
        }

        if (request.Game is null)
        {
            Console.WriteLine("[AddPlayerToGame] ERROR: Game is required but was null");
            throw new Exception("Game is required");
        }

        var meetingToken = await AddParticipantToMeetingAsync(request, playerId, cancellationToken);
        if (string.IsNullOrEmpty(meetingToken))
        {
            meetingToken = string.Empty;
        }

        var player = GamePlayer.Create(
            long.Parse(request.GameId),
            playerId,
            meetingToken ?? string.Empty
        );
        await DynamoDbService.WriteGamePlayerAsync(player, cancellationToken);

        CachingService.AddPlayer(player);

        var user = await DynamoDbService.ReadUserAsync(playerId, cancellationToken);
        CachingService.AddUser(user);

        await CachingService.Save(cancellationToken);
    }

    private async Task<string> AddParticipantToMeetingAsync(
        JoinX01GameCommand request,
        string playerId,
        CancellationToken cancellationToken
    )
    {
        if (request.Game is null)
        {
            Console.WriteLine("[AddParticipantToMeeting] ERROR: Game is required but was null");
            throw new Exception("Game is required");
        }

        var meeting = await MeetingService.GetByIdAsync(
            request.Game.MeetingIdentifier,
            cancellationToken
        );

        if (meeting is null)
        {
            Console.WriteLine(
                $"[AddParticipantToMeeting] ERROR: Meeting not found for ID {request.Game.MeetingIdentifier}"
            );
            throw new Exception("Meeting not found");
        }

        if (meeting.Id is null)
        {
            Console.WriteLine(
                "[AddParticipantToMeeting] ERROR: Meeting ID is required but was null"
            );
            throw new Exception("Meeting ID is required");
        }

        var meetingId = meeting.Id ?? throw new Exception("Meeting ID is required");

        var joinMeetingRequest = new JoinMeetingRequest(meetingId, request.PlayerName, playerId);

        var participantToken = await MeetingService.AddParticipantAsync(
            joinMeetingRequest,
            cancellationToken
        );

        if (participantToken is null)
        {
            Console.WriteLine(
                $"[AddParticipantToMeeting] ERROR: Failed to add participant {playerId} to meeting"
            );
            throw new Exception("Failed to add participant to meeting");
        }

        return participantToken ?? throw new Exception("Failed to get participant token");
    }

    private async Task StartGameIfReadyAsync(
        JoinX01GameCommand request,
        CancellationToken cancellationToken
    )
    {
        var currentPlayerCount = CachingService.State.Players.Count;

        if (currentPlayerCount != 2)
        {
            return;
        }

        request.Game!.Status = GameStatus.Started;
        request.Game!.LSI1 = $"{GameStatus.Started}#{request.Game!.GameId}";
        request.Game!.SortKey = $"{request.Game!.GameId}#{GameStatus.Started}";

        await DynamoDbService.PutGameAsync(request.Game, cancellationToken);

        CachingService.AddGame(request.Game);
        await CachingService.Save(cancellationToken);
    }
}
