# KISSmo Perl Pastebin

KISSmo Perl is a lightweight and efficient pastebin application built with Mojolicious. This guide provides comprehensive instructions for setting up and running the application, including troubleshooting common dependency issues on various operating systems.

---

## Table of Contents

* [Features](#features)
* [Setting Up and Running KISSmo Perl](#setting-up-and-running-kissmo-perl)
    * [Step 1: Install Required Modules](#step-1-install-required-modules)
    * [Step 2: Create the SQLite Database](#step-2-create-the-sqlite-database)
    * [Step 3: Run the Perl Script](#step-3-run-the-perl-script)
    * [Step 4: Access the Application](#step-4-access-the-application)
    * [Step 5: Test the Application](#step-5-test-the-application)
    * [Step 6: Accessing Raw Paste Data](#step-6-accessing-raw-paste-data)
* [Troubleshooting Common Perl Module Issues](#troubleshooting-common-perl-module-issues)
* [Release Notes](#release-notes)
* [Demo](#demo)

---

## Features

* Simple and efficient paste management.
* Uses SQLite for data storage.
* Web interface for creating and viewing pastes.
* Raw paste data access.

---

## Setting Up and Running KISSmo Perl

This guide assumes you're using a Unix-like system (e.g., Linux, \*BSD, or macOS) and have Perl installed.

### Step 1: Install Required Modules

Before running the code, you need to install the necessary Perl modules. The recommended approach is to use your operating system's package manager, as this ensures proper integration and dependency management.

**General Fallback (Using `cpanm`):**

If your distribution's packages are unavailable or outdated, you can use **cpanminus**. First, ensure `cpanminus` is installed:

```bash
sudo cpan App::cpanminus # Or `sudo apt install cpanminus`, `sudo apk add perl-app-cpanminus`, etc.

```

Then, install the modules:

Bash

```
sudo cpanm Mojolicious DBI File::Slurp DBD::SQLite

```

**Operating System Specific Instructions:**

----------

#### Debian (and Ubuntu, Pop!_OS, Mint, etc.)

Bash

```
sudo apt update
sudo apt install libmojolicious-perl libdbi-perl libfile-slurp-perl libdbd-sqlite3-perl

```

----------

#### Alpine Linux

Bash

```
sudo apk update
sudo apk add perl perl-mojolicious perl-dbi perl-file-slurp perl-dbd-sqlite

```

----------

#### OpenBSD

```
doas pkg_add perl-Mojolicious perl-DBI perl-File-Slurp perl-DBD-SQLite

```

----------

#### Arch Linux (and Manjaro, EndeavourOS, etc.)

```
sudo pacman -Sy
sudo pacman -S perl-mojolicious perl-dbi perl-file-slurp perl-dbd-sqlite

```

----------

### Step 2: Create the SQLite Database

The application uses an SQLite database to store pastes. Create an empty SQLite database file named `pastes.db` and a directory for pastes in the same directory as your Perl script.

```
touch pastes.db && mkdir pastes

```

### Step 3: Run the Perl Script

Once you've installed the modules and created the database file, navigate to the directory containing your script and execute the following command:

```
perl paste.pl daemon -m production -l http://0.0.0.0:7878

```

This command starts the Mojolicious application as a daemon process, listening on all network interfaces on port `7878`. You should see output similar to:

```
[Sun Jun 23 12:34:56 2023] [info] Listening at "http://<your_server_ip>:7878"

```

### Step 4: Access the Application

Open a web browser and visit `http://<your_server_ip>:7878` to access the application. Replace `<your_server_ip>` with the actual IP address or hostname of the machine running the script. You should be presented with a web page featuring a text area for content input.

### Step 5: Test the Application

To test the application, enter some content into the text area and click the "**Create paste**" button. The application will generate a unique ID for the paste and display its details.

### Step 6: Accessing Raw Paste Data

To view the raw content of a paste, navigate to its detail page and click the "**RAW**" button.

----------

## Troubleshooting Common Perl Module Issues

If you encounter errors like `Can't locate Mojolicious/Lite.pm in @INC`, `Can't locate DBI.pm in @INC`, `Can't locate File/Slurp.pm in @INC`, or `install_driver(SQLite) failed: Can't locate DBD/SQLite.pm in @INC`, it means the required Perl modules aren't found in your system's Perl library paths.

These issues are typically resolved by installing the missing modules. Refer to **Step 1: Install Required Modules** and use the instructions specific to your operating system. Ensure you're installing the correct package names as provided for Debian, Alpine, OpenBSD, or Arch Linux. If your system's package manager doesn't provide the module, or you need a specific version, **cpanminus** is a reliable alternative.

----------

## Release Notes

For detailed information about the latest version, KISSmo 1.1.9, please refer to the official release notes:

[https://git.hax.al/KISSmoPerl/tag/?h=v1.9](https://git.hax.al/KISSmoPerl/tag/?h=v1.9)

----------

## Demo

Experience KISSmo Perl in action:

[https://paste.hax.al/](https://paste.hax.al/)
