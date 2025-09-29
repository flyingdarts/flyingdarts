using System.Text.Json;

namespace Flyingdarts.Persistence;

public class CachingService<T> : ICachingService<T>
    where T : IGameState<T>
{
    private IDynamoDBContext DbContext = null!;

    public CachingService() { }

    public CachingService(IDynamoDBContext dbContext)
    {
        DbContext = dbContext;
    }

    public T State { get; set; } = default!;

    public async Task Load(string gameId, CancellationToken cancellationToken)
    {
        try
        {
            var results = await DbContext
                .FromQueryAsyncCompat<T>(Query(gameId), OperationConfig)
                .GetRemainingAsync(cancellationToken);

            if (results != null && results.Any())
            {
                State = results.Single();
            }
            else
            {
                State = default!;
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine(
                $"[ERROR] CachingService.Load - Failed to load state for gameId {gameId}: {ex.Message}"
            );
            Console.WriteLine($"[ERROR] CachingService.Load - Exception type: {ex.GetType().Name}");
            Console.WriteLine($"[ERROR] CachingService.Load - Stack trace: {ex.StackTrace}");
            throw;
        }
    }

    public async Task Save(CancellationToken cancellationToken)
    {
        if (State == null)
        {
            throw new InvalidOperationException("State is null, cannot save");
        }

        try
        {
            var stateWrite = DbContext.CreateBatchWriteCompat<T>(OperationConfig);
            stateWrite.AddPutItem(State);
            await stateWrite.ExecuteAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] CachingService.Save - Failed to save state: {ex.Message}");
            Console.WriteLine($"[ERROR] CachingService.Save - Exception type: {ex.GetType().Name}");
            Console.WriteLine($"[ERROR] CachingService.Save - Stack trace: {ex.StackTrace}");
            throw;
        }
    }

    private static QueryOperationConfig Query(string gameId)
    {
        var queryFilter = new QueryFilter("PK", QueryOperator.Equal, "X01State");
        queryFilter.AddCondition("SK", QueryOperator.BeginsWith, gameId);
        return new QueryOperationConfig { Filter = queryFilter };
    }

    private DynamoDBOperationConfig OperationConfig
    {
        get
        {
            var stateType = typeof(T);
            var tableName =
                $"Flyingdarts-{stateType.Name}-Table-{Environment.GetEnvironmentVariable("EnvironmentName")}";
            return new DynamoDBOperationConfig { OverrideTableName = tableName };
        }
    }

    public void CreateInitial(T state, Game game)
    {
        State = state;
        AddGame(game);
    }

    public void AddGame(Game game)
    {
        State.Game = game;
    }

    public void AddPlayer(GamePlayer player)
    {
        if (!State.Players.Any(x => x.PlayerId == player.PlayerId))
            State.Players.Add(player);
    }

    public void AddDart(GameDart dart)
    {
        if (State == null)
        {
            throw new InvalidOperationException("State is null, cannot add dart");
        }

        State.Darts.Add(dart);
    }

    public void AddUser(User user)
    {
        if (State != null && !State.Users.Any(x => x.UserId == user.UserId))
            State.Users.Add(user);
    }
}
