Scanventory
"Scan your stock away!"

Scanventory is an automated inventory management system designed specifically for startups. It bridges the gap for businesses that need a digital tracking system but lack the funding for permanent, payment-integrated solutions. By utilizing barcode scanning and unique stock IDs, Scanventory streamlines the tracking process and automates item tallying for both web and mobile platforms.

Key Features
Automated Tallying: Seamlessly connects to external barcode scanners to automate stock inflow and outflow.
Smart Registration: Automatically detects barcodes with no matching data and prompts the user to register the new item (Name, Category, Initial Quantity, Unit Price).
Advanced Search: Implements Binary Search algorithms for lightning-fast item lookups.
Inventory Alerts: Integrated warning system for low and critical stock levels.
Cloud Connectivity: Optional online backup and data synchronization via Google Drive or Dropbox.
Analytics Dashboard: A comprehensive overview tab featuring total inventory value, item breakdown, and stock statistics.

Tech Stack
Frontend: Flutter & Dart (Cross-platform Web & Mobile)
IoT/Hardware: Barcode Scanners & Arduino (Serial communication via Strings)
Cloud/Storage: Local Storage with Cloud Integration (Google Drive/Dropbox API)
Utilities: Wi-Fi/Mobile Data for real-time scanner connectivity.

Installation & Setup
Prerequisites
Flutter SDK installed and configured.
Git installed on your local machine.

Repository Setup
Clone the repository:
git clone https://github.com/nemesea05/group-2-scanventory-.git

Navigate to the project directory:
cd group-2-scanventory-

Install dependencies:
flutter pub get

Run the application:
flutter run

Hardware Integration
To use the automated scanning feature:
Connect your Barcode Scanner to your device via Wi-Fi or Bluetooth.
If using an Arduino setup, ensure the device is configured to send data as Strings over the connection.
The app will automatically catch the input and update the inventory tally.

Contributors (Group 2)
Jerome Miguel Bumanlag
Kaiser Gabriel Reyes
John Lloyd Lacumba
Chrishane Dela Peña

Instructor: Ryan Christopher Pinca (rcpinca.it@tip.edu.ph)
