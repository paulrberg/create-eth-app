import chalk from "chalk";  // Library for colored terminal output
import fsExtra from "fs-extra";  // Extra utilities for file system operations
import path from "path";  // Module for working with file and directory paths
import tempy from "tempy";  // Temporary directory and file creation

import { isDirectoryEmpty, isDirectoryWriteable } from "../../src/helpers/directories";  // Importing helper functions for directory checks

// List of valid files and directories to be in sync with 'helpers/directories'.
// Each entry is an array containing a file/directory name and its type ("file" or "directory").
const filesDirsTable: string[][] = [
  [".DS_Store", "file"],
  [".git", "directory"],
  [".gitattributes", "file"],
  [".gitignore", "file"],
  [".gitlab-ci.yml", "file"],
  [".hg", "directory"],
  [".hgcheck", "file"],
  [".hgignore", "file"],
  [".idea", "directory"],
  ["Thumbs.db", "file"],
  [".travis.yml", "file"],
  ["docs", "directory"],
  ["LICENSE", "file"],
  ["mkdocs.yml", "file"],
  ["npm-debug.log", "file"],
  ["yarn-debug.log", "file"],
  ["yarn-error.log", "file"],
  ["proj.iml", "file"],
];

describe("directories", function () {
  const appName: string = "my-eth-app";  // Application name used for testing purposes
  let testDirPath: string;  // Variable to hold the path of the temporary test directory

  beforeEach(function () {
    testDirPath = tempy.directory();  // Create a temporary directory before each test
  });

  // Test when the directory is empty
  describe("when the directory is empty", function () {
    test("returns true", function () {
      // Expect that an empty directory returns true
      expect(isDirectoryEmpty(testDirPath, appName)).toBe(true);
    });
  });

  // Test when the directory is not empty and contains valid files or directories
  describe("when the directory is not empty", function () {
    // Dynamically test each file/directory in the filesDirsTable
    describe.each(filesDirsTable)('when it contains a "%s" %s', function (name: string, type: string) {
      beforeEach(async function () {
        if (type === "file") {
          // If the type is 'file', create an empty file in the directory
          await fsExtra.open(path.join(testDirPath, name), "w");
        } else if (type === "directory") {
          // If the type is 'directory', create a directory
          await fsExtra.mkdir(path.join(testDirPath, name));
        }
      });

      test("returns true", async function () {
        // Expect that a non-empty directory returns true
        expect(isDirectoryEmpty(testDirPath, appName)).toBe(true);
      });
    });

    // Test when the directory contains no valid files or directories
    describe("when it contains no valid directories or files", function () {
      beforeEach(function () {
        console.log = jest.fn();  // Mock console.log to check if it gets called
      });

      // Test when it contains an invalid 'foo' directory
      describe("when it contains a foo directory", function () {
        beforeEach(async function () {
          await fsExtra.mkdir(path.join(testDirPath, "foo"));  // Create a 'foo' directory
        });

        test("returns conflicts", async function () {
          const result: boolean = isDirectoryEmpty(testDirPath, appName);  // Check for conflicts
          expect(console.log).toHaveBeenCalledWith(
            "The directory " + chalk.green(appName) + " contains files that could conflict:",
          );
          expect(console.log).toHaveBeenCalledWith();
          expect(console.log).toHaveBeenCalledWith(`  ${chalk.blue("foo")}/`);  // Expect 'foo' to be logged as conflicting
          expect(console.log).toHaveBeenCalledWith();
          expect(console.log).toHaveBeenCalledWith(
            "Either try using a new directory name, or remove the files listed above.",
          );
          expect(console.log).toHaveBeenCalledWith();
          expect(result).toBe(false);  // Expect that the result is false due to conflicts
        });
      });

      // Test when it contains an invalid 'bar' file
      describe("when it contains a bar file", function () {
        beforeEach(async function () {
          await fsExtra.open(path.join(testDirPath, "bar"), "w");  // Create a 'bar' file
        });

        test("returns conflicts", async function () {
          const result: boolean = isDirectoryEmpty(testDirPath, appName);  // Check for conflicts
          expect(console.log).toHaveBeenCalledWith(
            "The directory " + chalk.green(appName) + " contains files that could conflict:",
          );
          expect(console.log).toHaveBeenCalledWith();
          expect(console.log).toHaveBeenCalledWith("  bar");  // Expect 'bar' to be logged as conflicting
          expect(console.log).toHaveBeenCalledWith();
          expect(console.log).toHaveBeenCalledWith(
            "Either try using a new directory name, or remove the files listed above.",
          );
          expect(console.log).toHaveBeenCalledWith();
          expect(result).toBe(false);  // Expect that the result is false due to conflicts
        });
      });
    });
  });

  // Test when the directory is not writable
  describe("when the directory is not writable", function () {
    beforeEach(async function () {
      await fsExtra.chmod(testDirPath, 0o444);  // Set directory permissions to read-only
    });

    test("returns false", async function () {
      // Expect the directory to be non-writable
      await expect(isDirectoryWriteable(testDirPath)).resolves.toBe(false);
    });
  });

  // Test when the directory is writable
  describe("when the directory is writable", function () {
    beforeEach(async function () {
      await fsExtra.chmod(testDirPath, 0o777);  // Set directory permissions to writable
    });

    test("returns true", async function () {
      // Expect the directory to be writable
      await expect(isDirectoryWriteable(testDirPath)).resolves.toBe(true);
    });
  });

  // Cleanup: Remove the temporary test directory after each test
  afterEach(function () {
    fsExtra.removeSync(testDirPath);
  });
});
