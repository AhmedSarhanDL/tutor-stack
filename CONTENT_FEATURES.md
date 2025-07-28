# Content Management Features

This document describes the new content management features added to the Tutor Stack platform, including PDF upload functionality and curriculum viewing capabilities.

## Features Overview

### 1. PDF Upload System
- **Location**: `/pdf-upload` route
- **Purpose**: Upload and manage PDF files for educational content
- **Features**:
  - Drag-and-drop file upload interface
  - File type validation (PDF only)
  - File size validation (max 10MB)
  - Optional description field
  - Real-time upload progress
  - List of uploaded files with metadata

### 2. Curriculum Viewer
- **Location**: `/curriculum` route
- **Purpose**: Browse and explore the unified curriculum data
- **Features**:
  - Interactive concept cards with expandable details
  - Search functionality across concepts and descriptions
  - Detailed modal view for each concept
  - Sub-concept exploration
  - Examples and descriptions for each concept

## Backend Implementation

### Content Service Endpoints

#### PDF Upload Endpoints
```http
POST /content/upload-pdf
Content-Type: multipart/form-data

Parameters:
- file: PDF file (required)
- description: Optional description (optional)

Response:
{
  "filename": "document.pdf",
  "file_id": "uuid-string",
  "size": 1024000,
  "content_type": "application/pdf"
}
```

```http
GET /content/uploaded-files

Response:
{
  "files": [
    {
      "id": "uuid-string",
      "filename": "document.pdf",
      "size": 1024000,
      "content_type": "application/pdf",
      "description": "Optional description",
      "uploaded_at": "2024-01-01T00:00:00Z",
      "status": "processed"
    }
  ]
}
```

#### Curriculum Endpoints
```http
GET /content/curriculum

Response:
{
  "concepts": [
    {
      "name": "Concept Name",
      "description": "Concept description",
      "examples": ["Example 1", "Example 2"],
      "sub_concepts": [
        {
          "name": "Sub-concept Name",
          "description": "Sub-concept description",
          "examples": ["Sub-example 1", "Sub-example 2"]
        }
      ]
    }
  ]
}
```

```http
GET /content/curriculum/concepts

Response:
{
  "concepts": [/* array of concepts without full details */]
}
```

```http
GET /content/curriculum/concepts/{concept_name}

Response:
{
  "name": "Concept Name",
  "description": "Concept description",
  "examples": ["Example 1", "Example 2"],
  "sub_concepts": [/* sub-concepts array */]
}
```

### Data Source
The curriculum data is sourced from `services/content/unified_curriculum.json`, which contains a comprehensive collection of mathematical concepts, examples, and sub-concepts.

## Frontend Implementation

### Components

#### PdfUploadPage.tsx
- **File**: `frontend/src/components/PdfUploadPage.tsx`
- **CSS**: `frontend/src/components/PdfUploadPage.css`
- **Features**:
  - Drag-and-drop interface
  - File validation
  - Upload progress indication
  - File list with metadata
  - Error handling and success messages

#### CurriculumViewer.tsx
- **File**: `frontend/src/components/CurriculumViewer.tsx`
- **CSS**: `frontend/src/components/CurriculumViewer.css`
- **Features**:
  - Search functionality
  - Expandable concept cards
  - Modal detail view
  - Responsive design
  - Loading and error states

### Navigation
Both features are accessible from the main Dashboard:
- **PDF Upload**: "📄 Upload PDF" button
- **Curriculum Viewer**: "📚 View Curriculum" button

## Technical Details

### Dependencies Added
- `python-multipart==0.0.9` - For handling file uploads in FastAPI

### File Structure
```
services/content/
├── tutor_stack_content/
│   └── main.py (updated with new endpoints)
├── unified_curriculum.json (data source)
└── requirements.txt (updated)

frontend/src/components/
├── PdfUploadPage.tsx (new)
├── PdfUploadPage.css (new)
├── CurriculumViewer.tsx (new)
└── CurriculumViewer.css (new)
```

### API Integration
The frontend components use the existing `api` instance from `AuthContext` to communicate with the backend endpoints.

## Usage Instructions

### PDF Upload
1. Navigate to the Dashboard
2. Click "📄 Upload PDF" button
3. Either drag and drop a PDF file or click "Choose File"
4. Optionally add a description
5. The file will be uploaded and appear in the list below

### Curriculum Viewer
1. Navigate to the Dashboard
2. Click "📚 View Curriculum" button
3. Use the search bar to find specific concepts
4. Click on concept cards to expand details
5. Click "View Full Details" to see complete information in a modal

## Security Considerations

### PDF Upload
- File type validation (PDF only)
- File size limits (10MB max)
- Server-side validation
- Dummy implementation (files not actually stored)

### Curriculum Access
- Read-only access to curriculum data
- No sensitive information in curriculum JSON
- Public educational content

## Future Enhancements

### PDF Upload
- Actual file storage implementation
- PDF text extraction
- Content indexing for search
- File versioning
- User-specific file management

### Curriculum Viewer
- Bookmarking functionality
- Progress tracking
- Interactive exercises
- Related content suggestions
- Export functionality

## Testing

### Backend Testing
```bash
# Test health endpoint
curl http://localhost:8001/health

# Test curriculum endpoint
curl http://localhost:8001/curriculum

# Test uploaded files endpoint
curl http://localhost:8001/uploaded-files
```

### Frontend Testing
1. Start the development server: `npm run dev`
2. Navigate to the application
3. Test PDF upload with a sample PDF file
4. Test curriculum viewer search and navigation

## Error Handling

### Common Issues
- **File too large**: Check file size (max 10MB)
- **Invalid file type**: Ensure file is PDF format
- **Network errors**: Check API connectivity
- **Curriculum loading**: Verify JSON file exists and is valid

### Debug Information
- Browser console logs for frontend issues
- Backend logs for API issues
- Network tab for request/response debugging

## Performance Considerations

### PDF Upload
- Client-side file validation
- Progress indication for large files
- Efficient file handling

### Curriculum Viewer
- Lazy loading of concept details
- Efficient search implementation
- Responsive design for mobile devices

## Browser Compatibility

### Supported Browsers
- Chrome (recommended)
- Firefox
- Safari
- Edge

### Required Features
- File API support (for drag-and-drop)
- Fetch API support
- Modern CSS features

## Deployment Notes

### Environment Variables
No additional environment variables required for these features.

### Dependencies
Ensure `python-multipart` is installed in the content service environment.

### File Permissions
Ensure the content service has read access to `unified_curriculum.json`. 