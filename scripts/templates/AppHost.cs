// Local orchestration: run this project to start the whole backend.
// Docker Desktop must be running (SQL Server and Azurite run as containers).

var builder = DistributedApplication.CreateBuilder(args);

// Azure SQL locally → SQL Server container. Data survives restarts thanks to the volume.
var sql = builder.AddSqlServer("sql")
    .WithDataVolume();
var db = sql.AddDatabase("coolclouds");

// Blob Storage + Queues locally → Azurite emulator.
var storage = builder.AddAzureStorage("storage")
    .RunAsEmulator();
var blobs = storage.AddBlobs("blobs");

var api = builder.AddProject<Projects.CoolClouds_Api>("api")
    .WithReference(db)
    .WithReference(blobs)
    .WaitFor(db)
    .WaitFor(storage)
    .WithExternalHttpEndpoints();

builder.AddAzureFunctionsProject<Projects.CoolClouds_Functions>("functions")
    .WithHostStorage(storage)
    .WithReference(db)
    .WithReference(blobs)
    .WaitFor(db);

// Later: Service Bus emulator for the notifications queue
// var bus = builder.AddAzureServiceBus("bus").RunAsEmulator();

builder.Build().Run();
