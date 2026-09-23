using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace StudentManagement.API.Migrations
{
    /// <inheritdoc />
    public partial class AddOrganizationSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "OrganizationId",
                table: "Users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OrganizationId",
                table: "Students",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OrganizationId",
                table: "Courses",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Organizations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Organizations", x => x.Id);
                });

// ============================================================
// CREATE DEFAULT ORGANIZATION FOR EXISTING DATA
// ============================================================

migrationBuilder.InsertData(
    table: "Organizations",
    columns: new[] { "Id", "Name", "IsActive", "CreatedAt" },
    values: new object[]
    {
        1,
        "Default Organization",
        true,
        DateTime.UtcNow
    });

// ============================================================
// ASSIGN EXISTING DATA TO DEFAULT ORGANIZATION
// ============================================================

migrationBuilder.Sql(
    """
    UPDATE "Users"
    SET "OrganizationId" = 1
    WHERE "OrganizationId" IS NULL;
    """);

migrationBuilder.Sql(
    """
    UPDATE "Students"
    SET "OrganizationId" = 1
    WHERE "OrganizationId" IS NULL;
    """);

migrationBuilder.Sql(
    """
    UPDATE "Courses"
    SET "OrganizationId" = 1
    WHERE "OrganizationId" IS NULL;
    """);

            migrationBuilder.CreateIndex(
                name: "IX_Users_OrganizationId",
                table: "Users",
                column: "OrganizationId");

            migrationBuilder.CreateIndex(
                name: "IX_Students_OrganizationId",
                table: "Students",
                column: "OrganizationId");

            migrationBuilder.CreateIndex(
                name: "IX_Courses_OrganizationId",
                table: "Courses",
                column: "OrganizationId");

            migrationBuilder.AddForeignKey(
                name: "FK_Courses_Organizations_OrganizationId",
                table: "Courses",
                column: "OrganizationId",
                principalTable: "Organizations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Students_Organizations_OrganizationId",
                table: "Students",
                column: "OrganizationId",
                principalTable: "Organizations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Organizations_OrganizationId",
                table: "Users",
                column: "OrganizationId",
                principalTable: "Organizations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Courses_Organizations_OrganizationId",
                table: "Courses");

            migrationBuilder.DropForeignKey(
                name: "FK_Students_Organizations_OrganizationId",
                table: "Students");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Organizations_OrganizationId",
                table: "Users");

            migrationBuilder.DropTable(
                name: "Organizations");

            migrationBuilder.DropIndex(
                name: "IX_Users_OrganizationId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Students_OrganizationId",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_Courses_OrganizationId",
                table: "Courses");

            migrationBuilder.DropColumn(
                name: "OrganizationId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "OrganizationId",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "OrganizationId",
                table: "Courses");
        }
    }
}
