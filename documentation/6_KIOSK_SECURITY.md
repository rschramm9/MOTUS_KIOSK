# Network and Computer Security for Motus Kiosk

### Who do I talk to?

-   Owner/Originator: Richard Schramm - [schramm.r@gmail.com](mailto:schramm.r@gmail.com){.email}

### 1.0 - Keeping your Motus Kiosk secure.

Your computer and  network IT staff may have concerns regarding allowing your MOTUS_KIOSK on their infrastructure or wifi network. 

The application was developed to be run at a USFWS Nature Center on the Ankeny National Wildlife Refuge. The center is used as a classroom by local school groups, as a meeting room for local non-profit organizations, and for refuge events.
Refuge staff is often not available on site to supervise so security against misuse is a top priority.

One of the core requirements of the app is as a "kiosk" it needs to be 'completely locked down'.
A great deal of attention was paid to securing the kiosk as we did not want anyone to access user
accounts or go browsing off to where they shouldnt. 
- no one can access the user accounts or windows desktop.
- no one can access the cmd console to run commands or programs
- no one can browse to off-site or off-kiosk web sites or URL's
- runs without an attached keyboard - no access to keyboard keycombo escapes 
- only the system administrator account has access to a windows desktop via
an OpenKiosk password protected escape sequence that requires a connected
keyboard.
- For additional security it is recommended to lock the computer itself in a cabinet along with
the keyboard so there is no access to the power button. 

The data queries are made within the application as simple http requests straight to motus.org public access data server.  All of that is hidden within the application completely out of sight and reach of the Motus user.

The networking requirements for internet bandwidth for the app is quite low. 
Data are cached locally to minimize the http requests going out to the motus.org server.
Only the minimum required data is requested and then only if it's not available in the cache.

There is no motus.org login, password, account etc required to retrieve data from motus.
Cache use and frequency parameters are set via your kiosk.cfg file.

***You as administrator are responsible to understand and maintain security.***
Some ways security may be compromised are:

- Administrator not correctly configuring the security settings for OpenKiosk
- Modifying the html homepage, species pages etc by adding hypertext links that go 'off-app' or 'off-site'. The kiosk app would have no way to regain control if you were to allow this.
-  Sharing or not securing the Administrator account password.
-  Allowing the computer to be used for other tasks or by other users.

Occasionally someone responsible on-site may need access to power cycle the
computer if the touchscreen becomes unresponsive. This has been typically due to power
outages and frequency can be reduced by using a small UPS backup battery.

Additonal information about OpenKiosk is available at: https://openkiosk.mozdevgroup.com/

The github project that contains the software and documentation is available at :
https://github.com/rschramm9/MOTUS_KIOSK
