FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Postapic.csproj", "."]
RUN dotnet restore "Postapic.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "Postapic.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Postapic.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Postapic.dll"]
