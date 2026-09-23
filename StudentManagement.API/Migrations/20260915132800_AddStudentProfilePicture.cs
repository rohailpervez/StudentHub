using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentManagement.API.Migrations
{
    /// <inheritdoc />
    public partial class AddStudentProfilePicture : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ProfilePictureFileName",
                table: "Students",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProfilePicturePath",
                table: "Students",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ProfilePictureFileName",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "ProfilePicturePath",
                table: "Students");
        }
    }
}
