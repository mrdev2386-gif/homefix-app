// Firestore Payload Example for Step 4 - Work Portfolio
// Collection: technicians/{uid}

{
  // ... other technician fields ...
  
  "portfolioPhotos": [
    "https://firebasestorage.googleapis.com/v0/b/homefix-aa42d.appspot.com/o/technicians%2F{uid}%2Fportfolio%2F1703123456789.jpg?alt=media&token=...",
    "https://firebasestorage.googleapis.com/v0/b/homefix-aa42d.appspot.com/o/technicians%2F{uid}%2Fportfolio%2F1703123456790.jpg?alt=media&token=...",
    "https://firebasestorage.googleapis.com/v0/b/homefix-aa42d.appspot.com/o/technicians%2F{uid}%2Fportfolio%2F1703123456791.jpg?alt=media&token=..."
  ],
  
  // Firebase Storage paths for uploaded photos:
  // technicians/{uid}/portfolio/1703123456789.jpg
  // technicians/{uid}/portfolio/1703123456790.jpg
  // technicians/{uid}/portfolio/1703123456791.jpg
  
  "updatedAt": "2024-01-15T10:30:00Z"
}

// Step 4 Data Payload sent to Cloud Function:
{
  "portfolioPhotos": [
    "https://firebasestorage.googleapis.com/v0/b/homefix-aa42d.appspot.com/o/technicians%2F{uid}%2Fportfolio%2F1703123456789.jpg?alt=media&token=...",
    "https://firebasestorage.googleapis.com/v0/b/homefix-aa42d.appspot.com/o/technicians%2F{uid}%2Fportfolio%2F1703123456790.jpg?alt=media&token=..."
  ]
}