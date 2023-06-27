# KP
KISSmo perl version

## Setting up and Running the KISSmo Perl

To set up and run the Perl code you provided, follow the steps below. This guide assumes you are using a Unix-like system (e.g., Linux or macOS) and have Perl installed.

### Step 1: Install Required Modules

Before running the code, you need to install the required Perl modules. Open your terminal and execute the following command:

`cpanm Mojolicious DBI File::Slurp` 

This command uses the `cpanm` tool to install the necessary modules (`Mojolicious`, `DBI`, and `File::Slurp`). If you don't have `cpanm` installed, you can install it by running `cpan App::cpanminus`.

### Step 2: Create the SQLite Database

The code uses an SQLite database to store the pastes. Create an empty SQLite database file named `pastes.db` in the same directory as the Perl script. You can do this with the following command:

`touch pastes.db && mkdir pastes` 


### Step 3: Run the Perl Script

Once you have installed the modules and created the database file, you can run the Perl script. Open your terminal and navigate to the directory containing the script (`cd path/to/script`). Then execute the following command:

`perl paste.pl daemon -m production -l http://0.0.0.0:7878` 

This command starts the Mojolicious application as a daemon process. You should see output similar to:

`[Sun Jun 23 12:34:56 2023] [info] Listening at "http://ip:7878"` 

### Step 4: Access the Application

Open a web browser and visit `http://ip:7878` to access the application. You should see a web page with a text area where you can enter your content.

### Step 5: Test the Application

You can test the application by entering some content in the text area and clicking the "Create paste" button. The application will generate a unique ID for the paste and display the paste's details.

### Step 6: Accessing Raw Paste Data

To access the raw content of a paste, you can click the "RAW" button on the paste's detail page.

That's it! You have successfully set up and run the Perl script. You can continue using the application by creating and accessing pastes through the web interface.

**Note**: Remember to keep the terminal running while you want the application to be accessible. You can stop the application by pressing Ctrl+C in the terminal.

### Demo:

https://paste.hax.al/
