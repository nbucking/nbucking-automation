# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["NbuckingProject.Web.csproj", "."]
RUN dotnet restore "./NbuckingProject.Web.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "NbuckingProject.Web.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "NbuckingProject.Web.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "NbuckingProject.Web.dll"]
