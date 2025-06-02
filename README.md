# My Tool Shed

# My Tool Shed - Version 1.0.0  

## What's New 
- Initial release of My Tool Shed, a comprehensive tool management app 

## Features 
- 📝 Add and manage your tools with detailed information 
- 📸 Add photos to your tools for easy identification 
- 🔔 Get notifications for tools that are due for return 
- 📅 Track maintenance schedules for your tools 
- 📱 Modern Material Design 3 interface 
- 🔍 Easy search and filtering of tools 
- 📊 Visual status indicators for tool availability 
- 📝 Detailed borrowing history for each tool 
- 📱 Support for Android 6.0 (Marshmallow) and above 


## Tool Management 
- Add new tools with photos and descriptions 
- Track tool status (available, borrowed, maintenance needed) 
- Set maintenance intervals and get reminders 
- View detailed tool history 

## Borrowing System 
- Record borrower information (name, phone, email) 
- Set return dates and get notifications 
- Track borrowing history 
- Mark tools as returned
  
## User Interface 
- Clean and intuitive dashboard 
- Color-coded status indicators 
- Easy-to-use forms for adding and managing tools 
- Responsive design for all screen sizes 

## Technical Improvements 
- Optimized performance 
- Reduced app size 
- Improved battery efficiency 
- Enhanced stability 

## Requirements 
- Android 6.0 (Marshmallow) or higher 
- Internet connection for notifications 
- Camera permission for adding tool photos 

## Environment Setup

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Update the `.env` file with your Firebase configuration values:
- Get your Firebase configuration from the Firebase Console
- Replace all placeholder values with your actual Firebase configuration

3. Never commit the `.env` file to version control
- The `.env` file contains sensitive information and should be kept private
- Each developer should maintain their own `.env` file locally
