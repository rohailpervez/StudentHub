# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY ["StudentManagement.API.csproj", "./"]
RUN dotnet restore "StudentManagement.API.csproj"

# Copy the rest of the API source code
COPY . .

# Build and publish
RUN dotnet publish "StudentManagement.API.csproj" \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

# Render provides the PORT environment variable.
ENV ASPNETCORE_URLS=http://0.0.0.0:${PORT}

ENTRYPOINT ["dotnet", "StudentManagement.API.dll"]