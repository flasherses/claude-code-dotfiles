# Few-Shot Example: Java/Maven MCP Server

This is the complete CLAUDE.md generated for the AIContractReview-MCP project. Use as a reference for Java/Spring Boot/Maven projects.

```markdown
# AIContractReview MCP Server — Project CLAUDE.md

## 1. Project Goal

Contract Review MCP Server — exposes Chinese legal contract review capabilities as
standardized MCP tools for AI Agents. A streamlined standalone version of
aicontractreview-backend (Redis, SSO, cloud storage, frontend removed), keeping only
database access and LLM invocation.

Core flow: Contract Type Recognition -> Review Rule Query -> Enterprise Credit Query.

## 2. Tech Stack

| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Language | Java | 21 | |
| Build | Maven | 3.x | Multi-module: parent -> dao -> server |
| Framework | Spring Boot | 4.1.0 | @SpringBootApplication |
| MCP SDK | Spring AI MCP | 2.0.0 | @McpTool annotation |
| ORM | MyBatis-Plus | 3.5.12 | BaseMapper + @MapperScan |
| Database | PostgreSQL | 42.7.4 | Shared with aicontractreview-backend |
| Connection Pool | HikariCP | (built-in) | minIdle=2, maxPoolSize=10 |
| HTTP Client | Hutool | 5.8.36 | HttpUtil.createPost() / HttpUtil.get() |
| JSON | FastJSON | 1.2.83 | @JSONField aliases |
| Encryption | Jasypt | 3.0.5 | ENC() values + JASYPT_ENCRYPTOR_PASSWORD |
| Logging | Logback | (built-in) | Console + rolling file (100MB/30d/3GB) |

## 3. Directory Structure

```
aicontractreview-mcp/
├── pom.xml                              # Parent POM (aggregator)
├── aicr-mcp-dao/                        # Data access module
│   └── src/main/java/.../mcp/
│       ├── entity/                      # 6 entities (Lombok @Data)
│       └── mapper/                      # MyBatis-Plus BaseMapper
├── aicr-mcp-server/                     # Core service module
│   └── src/main/java/.../mcp/
│       ├── AicrMcpApplication.java      # @SpringBootApplication entry
│       ├── config/                      # DataSource + MyBatis config
│       ├── dto/                         # Data transfer objects
│       ├── service/                     # Business logic (LLM, HTTP, DB)
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
- AicrMcpApplication.java — entry point annotations

### Never Auto-Execute
- git push (private repo)
- mvn deploy
- Deleting any application-*.yml file

## 6. Common Commands

```shell
# Compile (skip tests — project has none)
mvn clean compile -DskipTests

# Package
mvn clean package -DskipTests

# Run (requires Jasypt decrypt key)
$env:JASYPT_ENCRYPTOR_PASSWORD="<key>"
mvn spring-boot:run -pl aicr-mcp-server

# Single module compile
mvn clean compile -pl aicr-mcp-dao -DskipTests

# Dependency tree
mvn dependency:tree -pl aicr-mcp-server

# MCP endpoint: http://localhost:8602/mcp
```
```

## Key Observations

1. **100-300 lines achieved** by referencing rules/ for detailed conventions instead of embedding them
2. **Every forbidden zone is actionable** — file path or command pattern
3. **Commands include necessary env vars** — `JASYPT_ENCRYPTOR_PASSWORD` is noted
4. **Directory structure only lists AI-relevant directories** — not every single file
5. **Tech stack table includes "Notes" column** explaining WHY each dependency is there
