using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentManagement.API.Migrations
{
    /// <inheritdoc />
    public partial class AddCourseRelationship : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Add the new CourseId column first.
            migrationBuilder.AddColumn<int>(
                name: "CourseId",
                table: "Students",
                type: "integer",
                nullable: true);

            // 2. Create Course records for any existing student course names
            // that don't already exist in the Courses table.
            migrationBuilder.Sql("""
                INSERT INTO "Courses"
                    ("Name", "Description", "DurationMonths", "IsActive")
                SELECT DISTINCT
                    TRIM(s."Course"),
                    '',
                    0,
                    TRUE
                FROM "Students" s
                WHERE TRIM(s."Course") <> ''
                  AND NOT EXISTS (
                      SELECT 1
                      FROM "Courses" c
                      WHERE LOWER(TRIM(c."Name")) = LOWER(TRIM(s."Course"))
                  );
                """);

            // 3. Connect existing students to their matching courses.
            migrationBuilder.Sql("""
                UPDATE "Students" s
                SET "CourseId" = c."Id"
                FROM "Courses" c
                WHERE TRIM(s."Course") <> ''
                  AND LOWER(TRIM(s."Course")) = LOWER(TRIM(c."Name"));
                """);

            // 4. Create the index.
            migrationBuilder.CreateIndex(
                name: "IX_Students_CourseId",
                table: "Students",
                column: "CourseId");

            // 5. Create the foreign-key relationship.
            migrationBuilder.AddForeignKey(
                name: "FK_Students_Courses_CourseId",
                table: "Students",
                column: "CourseId",
                principalTable: "Courses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            // 6. Now that the data has been transferred,
            // remove the old text-based Course column.
            migrationBuilder.DropColumn(
                name: "Course",
                table: "Students");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Restore the old Course text column.
            migrationBuilder.AddColumn<string>(
                name: "Course",
                table: "Students",
                type: "text",
                nullable: false,
                defaultValue: "");

            // Restore course names from the relationship.
            migrationBuilder.Sql("""
                UPDATE "Students" s
                SET "Course" = COALESCE(c."Name", '')
                FROM "Courses" c
                WHERE s."CourseId" = c."Id";
                """);

            migrationBuilder.DropForeignKey(
                name: "FK_Students_Courses_CourseId",
                table: "Students");

            migrationBuilder.DropIndex(
                name: "IX_Students_CourseId",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "CourseId",
                table: "Students");
        }
    }
}