# Few-Shot Example: Java/Maven MCP Server

This is a complete CLAUDE.md example for a Java/Spring Boot/Maven MCP Server project. Use as a reference when generating CLAUDE.md for similar projects.

```markdown
# Inventory MCP Server — Project CLAUDE.md

## 1. Project Goal

Inventory Query MCP Server — exposes inventory management capabilities as standardized
MCP tools for AI Agents. A streamlined standalone service that provides stock queries,
order status checks, and warehouse availability.

Core flow: Product Lookup -> Stock Check -> Availability Report.

## 2. Tech Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Language | Java | 21 | |
| Build | Maven | 3.x | Multi-module: parent -> dao -> server |
| Framework | Spring Boot | 4.1.0 | @SpringBootApplication |
| MCP SDK | Spring AI MCP | 2.0.0 | @McpTool annotation |
| ORM | MyBatis-Plus | 3.5.12 | BaseMapper + @MapperScan |
| Database | PostgreSQL | 42.7.4 | Shared with main backend |
| Connection Pool | HikariCP | (built-in) | minIdle=2, maxPoolSize=10 |
| HTTP Client | Hutool | 5.8.36 | HttpUtil.createPost() / HttpUtil.get() |
| Encryption | Jasypt | 3.0.5 | ENC() values + env var decrypt key |
| Logging | Logback | (built-in) | Console + rolling file |

## 3. Directory Structure

```
inventory-mcp/
├── pom.xml                              # Parent POM (aggregator)
├── inventory-mcp-dao/                   # Data access module
│   └── src/main/java/.../mcp/
│       ├── entity/                      # JPA/MyBatis entities
│       └── mapper/                      # Data mappers
├── inventory-mcp-server/                # Core service module
│   └── src/main/java/.../mcp/
│       ├── Application.java             # @SpringBootApplication entry
│       ├── config/                      # DataSource + framework config
│       ├── dto/                         # Data transfer objects
│       ├── service/                     # Business logic
│       └── tool/                        # MCP tools (@McpTool annotation)
└── docs/                                # Architecture + API docs
```

## 4. Code Conventions

[See java-conventions.md in rules/]

## 5. Forbidden Zones

### Must Ask Before Touching
- application-*.yml — contains encrypted credentials
- pom.xml — dependency changes affect entire build
- DataSourceConfig.java — DB connection configuration
- Application.java — entry point annotations

### Never Auto-Execute
- git push
- mvn deploy
- Deleting any application-*.yml file

## 6. Common Commands

```shell
# Compile (skip tests — add when tests exist)
mvn clean compile -DskipTests

# Package
mvn clean package -DskipTests

# Run (requires Jasypt decrypt key)
$env:JASYPT_ENCRYPTOR_PASSWORD="<key>"
mvn spring-boot:run -pl inventory-mcp-server

# Single module compile
mvn clean compile -pl inventory-mcp-dao -DskipTests

# Dependency tree
mvn dependency:tree -pl inventory-mcp-server
```
```

## Key Observations

1. **100-300 lines achieved** by referencing rules/ for detailed conventions
2. **Every forbidden zone is actionable** — file path or command pattern
3. **Commands include necessary env vars** — `JASYPT_ENCRYPTOR_PASSWORD` is noted
4. **Directory structure only lists AI-relevant directories**
5. **Tech stack table includes "Notes" column** explaining WHY each dependency
