# Peak Response

This is the iOS mobile app repository for Peak Response.

For the server repository, visit:

https://github.com/peakresponse/peak-server

Peak Response (formerly NaT/NaTriage) was developed as part of the 2019 Tech to Protect Challenge to create new technologies for emergency responders.


## Getting Started

1. Install Xcode from Apple: https://developer.apple.com/xcode/

2. Install CocoaPods, if you don't already have this utility: https://cocoapods.org/

3. Clone this git repo to a "local" directory (on your computer), then change
   into the directory.

   ```
   $ git clone https://github.com/peakresponse/peak-ios.git
   $ cd peak-ios
   ```

4. Install dependencies with CocoaPods.

   ```
   $ pod install
   ```

5. Open the _workspace_ in Xcode.

   ```
   $ open Triage.xcworkspace
   ```

6. Change the default API server hostname in ApiClient.swift. If you are
   developing locally on your computer with the simulator, you can change it
   to http://localhost:3000/. If you wish to use a device for testing,
   I recommend using a secure HTTPS proxy to the localhost server, such as
   ngrok: https://ngrok.com/

7. Build and run!

## Distribution

This source code is licensed under the GNU General Public License, which is
_incompatible_ with the terms of the Apple App Store. Only Peak Response,
as the original copyright holder, maintains an official release in the
App Store at the following link:

https://apps.apple.com/us/app/peak-response/id1532180261

An organization interested in deploying this software for private internal
use can sign up for the Apple Developer Enterprise Program. The app can then
be customized, built, and directly distributed within the organization using
an iOS compatible MDM (Mobile Device Management) solution, bypassing the
Apple App Store.

Other interested parties can contact Peak Response for custom apps distributed
through Apple Business Manager or for source code dual-licensing options.

## License

Peak Response  
Copyright (C) 2019-2021 Peak Response Inc

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Attributions

This repository contains icon artwork PDFs converted from SVGs downloaded from
Font Awesome, under the terms of the Font Awesome Free license and the
Creative Commons CC BY 4.0 license.

https://fontawesome.com/license/free

This repository contains font files licensed under the SIL Open Font License (OFL).

https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL
