#!/usr/bin/env python3
"""
Enhanced Documentation System - Documentation API Server
Phase 3 Day 5: Production Integration & Advanced Features
REST API for accessing generated documentation and module information
"""

import os
import json
import logging
import asyncio
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import aiofiles

from fastapi import FastAPI, HTTPException, Query, Path as PathParam
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel
import uvicorn

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Pydantic models
class ModuleInfo(BaseModel):
    id: str
    name: str
    version: str
    description: Optional[str] = None
    author: Optional[str] = None
    function_count: int
    last_updated: str

class FunctionInfo(BaseModel):
    name: str
    description: Optional[str] = None
    syntax: Optional[str] = None
    parameters: List[Dict[str, Any]] = []
    examples: List[Dict[str, Any]] = []
    module: str

class SearchResult(BaseModel):
    id: str
    name: str
    description: str
    module: str
    module_id: str
    type: str  # 'function', 'module', 'parameter'

class HealthStatus(BaseModel):
    status: str
    timestamp: str
    version: str = "1.0.0"
    services: Dict[str, str]

class DocumentationAPIServer:
    """FastAPI server for Enhanced Documentation System"""
    
    def __init__(self):
        self.docs_path = Path(os.environ.get('DOCS_PATH', '/docs/generated'))
        self.cache_path = Path(os.environ.get('CACHE_PATH', '/docs/cache'))
        self.modules_path = Path(os.environ.get('MODULES_PATH', '/app/modules'))
        
        # Ensure directories exist
        self.docs_path.mkdir(parents=True, exist_ok=True)
        self.cache_path.mkdir(parents=True, exist_ok=True)
        
        # Initialize FastAPI app
        self.app = FastAPI(
            title="Enhanced Documentation System API",
            description="REST API for Unity-Claude Enhanced Documentation System",
            version="1.0.0",
            docs_url="/docs",
            redoc_url="/redoc"
        )
        
        # Enable CORS
        if os.environ.get('ENABLE_CORS', 'true').lower() == 'true':
            self.app.add_middleware(
                CORSMiddleware,
                allow_origins=["*"],
                allow_credentials=True,
                allow_methods=["*"],
                allow_headers=["*"],
            )
        
        self.setup_routes()
        logger.info("Documentation API Server initialized")

    def setup_routes(self):
        """Setup API routes"""
        
        @self.app.get("/health", response_model=HealthStatus)
        async def health_check():
            """Health check endpoint"""
            return HealthStatus(
                status="healthy",
                timestamp=datetime.now().isoformat(),
                services={
                    "docs_api": "operational",
                    "file_system": "accessible" if self.docs_path.exists() else "unavailable",
                    "cache": "accessible" if self.cache_path.exists() else "unavailable"
                }
            )
        
        @self.app.get("/api/modules", response_model=List[ModuleInfo])
        async def get_modules():
            """Get list of all available modules"""
            try:
                modules = await self.scan_modules()
                return modules
            except Exception as e:
                logger.error(f"Error getting modules: {e}")
                raise HTTPException(status_code=500, detail="Failed to retrieve modules")
        
        @self.app.get("/api/modules/{module_id}")
        async def get_module_details(module_id: str = PathParam(..., description="Module identifier")):
            """Get detailed information about a specific module"""
            try:
                module_data = await self.get_module_data(module_id)
                if not module_data:
                    raise HTTPException(status_code=404, detail=f"Module '{module_id}' not found")
                return module_data
            except HTTPException:
                raise
            except Exception as e:
                logger.error(f"Error getting module {module_id}: {e}")
                raise HTTPException(status_code=500, detail="Failed to retrieve module details")
        
        @self.app.get("/api/functions", response_model=List[FunctionInfo])
        async def get_functions(
            module: Optional[str] = Query(None, description="Filter by module"),
            search: Optional[str] = Query(None, description="Search in function names/descriptions")
        ):
            """Get list of functions with optional filtering"""
            try:
                functions = await self.get_all_functions(module_filter=module, search_term=search)
                return functions
            except Exception as e:
                logger.error(f"Error getting functions: {e}")
                raise HTTPException(status_code=500, detail="Failed to retrieve functions")
        
        @self.app.get("/api/search", response_model=List[SearchResult])
        async def search_documentation(
            q: str = Query(..., description="Search query"),
            limit: int = Query(50, description="Maximum number of results")
        ):
            """Search across all documentation"""
            try:
                results = await self.search_content(q, limit)
                return results
            except Exception as e:
                logger.error(f"Error searching: {e}")
                raise HTTPException(status_code=500, detail="Search failed")
        
        @self.app.get("/api/search-data")
        async def get_search_data():
            """Get search index data for client-side search"""
            try:
                search_data = await self.build_search_index()
                return search_data
            except Exception as e:
                logger.error(f"Error building search data: {e}")
                raise HTTPException(status_code=500, detail="Failed to build search data")
        
        @self.app.get("/api/security/report")
        async def get_security_report():
            """Get latest security analysis report"""
            try:
                report_path = self.docs_path / "security" / "security_report.json"
                if not report_path.exists():
                    raise HTTPException(status_code=404, detail="Security report not available")
                
                async with aiofiles.open(report_path, 'r') as f:
                    content = await f.read()
                    return json.loads(content)
                    
            except HTTPException:
                raise
            except Exception as e:
                logger.error(f"Error getting security report: {e}")
                raise HTTPException(status_code=500, detail="Failed to retrieve security report")
        
        @self.app.get("/api/files/{file_path:path}")
        async def get_file(file_path: str):
            """Get generated documentation file"""
            try:
                full_path = self.docs_path / file_path
                if not full_path.exists() or not full_path.is_file():
                    raise HTTPException(status_code=404, detail="File not found")
                
                # Security check - ensure file is within docs directory
                try:
                    full_path.resolve().relative_to(self.docs_path.resolve())
                except ValueError:
                    raise HTTPException(status_code=403, detail="Access denied")
                
                return FileResponse(full_path)
                
            except HTTPException:
                raise
            except Exception as e:
                logger.error(f"Error serving file {file_path}: {e}")
                raise HTTPException(status_code=500, detail="Failed to serve file")

    async def scan_modules(self) -> List[ModuleInfo]:
        """Scan and return information about available modules"""
        modules = []
        
        try:
            # Look for module manifest files
            if self.modules_path.exists():
                for module_dir in self.modules_path.iterdir():
                    if module_dir.is_dir():
                        manifest_path = module_dir / f"{module_dir.name}.psd1"
                        if manifest_path.exists():
                            try:
                                module_info = await self.parse_module_manifest(manifest_path)
                                if module_info:
                                    modules.append(module_info)
                            except Exception as e:
                                logger.warning(f"Failed to parse manifest {manifest_path}: {e}")
            
            # Also look for generated documentation
            docs_modules_path = self.docs_path / "modules"
            if docs_modules_path.exists():
                for module_file in docs_modules_path.glob("*.json"):
                    try:
                        async with aiofiles.open(module_file, 'r') as f:
                            content = await f.read()
                            module_data = json.loads(content)
                            
                            # Check if already added from manifest scan
                            if not any(m.id == module_data.get('id') for m in modules):
                                modules.append(ModuleInfo(
                                    id=module_data.get('id', module_file.stem),
                                    name=module_data.get('name', module_file.stem),
                                    version=module_data.get('version', '1.0.0'),
                                    description=module_data.get('description'),
                                    author=module_data.get('author'),
                                    function_count=len(module_data.get('functions', [])),
                                    last_updated=module_data.get('last_updated', datetime.now().isoformat())
                                ))
                    except Exception as e:
                        logger.warning(f"Failed to parse module doc {module_file}: {e}")
            
            logger.info(f"Found {len(modules)} modules")
            return modules
            
        except Exception as e:
            logger.error(f"Error scanning modules: {e}")
            return []

    async def parse_module_manifest(self, manifest_path: Path) -> Optional[ModuleInfo]:
        """Parse PowerShell module manifest file"""
        try:
            # This is a simplified parser - in reality you'd want to use PowerShell to parse .psd1 files
            # For now, we'll extract basic information using text parsing
            async with aiofiles.open(manifest_path, 'r', encoding='utf-8') as f:
                content = await f.read()
            
            # Extract basic information using simple text matching
            module_name = manifest_path.parent.name
            version = "1.0.0"
            description = ""
            author = ""
            
            # Basic parsing of PowerShell data file
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if line.startswith('ModuleVersion'):
                    version = line.split('=')[1].strip().strip("'\"")
                elif line.startswith('Description'):
                    description = line.split('=')[1].strip().strip("'\"")
                elif line.startswith('Author'):
                    author = line.split('=')[1].strip().strip("'\"")
            
            return ModuleInfo(
                id=module_name,
                name=module_name,
                version=version,
                description=description,
                author=author,
                function_count=0,  # Will be updated when scanning functions
                last_updated=datetime.fromtimestamp(manifest_path.stat().st_mtime).isoformat()
            )
            
        except Exception as e:
            logger.warning(f"Failed to parse manifest {manifest_path}: {e}")
            return None

    async def get_module_data(self, module_id: str) -> Optional[Dict]:
        """Get detailed data for a specific module"""
        try:
            # Look for generated module documentation
            module_doc_path = self.docs_path / "modules" / f"{module_id}.json"
            if module_doc_path.exists():
                async with aiofiles.open(module_doc_path, 'r') as f:
                    content = await f.read()
                    return json.loads(content)
            
            # If no generated doc, create basic info from manifest
            manifest_path = self.modules_path / module_id / f"{module_id}.psd1"
            if manifest_path.exists():
                module_info = await self.parse_module_manifest(manifest_path)
                if module_info:
                    return {
                        "id": module_info.id,
                        "name": module_info.name,
                        "version": module_info.version,
                        "description": module_info.description,
                        "author": module_info.author,
                        "functions": [],
                        "last_updated": module_info.last_updated
                    }
            
            return None
            
        except Exception as e:
            logger.error(f"Error getting module data for {module_id}: {e}")
            return None

    async def get_all_functions(self, module_filter: Optional[str] = None, search_term: Optional[str] = None) -> List[FunctionInfo]:
        """Get all functions with optional filtering"""
        functions = []
        
        try:
            # Scan all module documentation files
            docs_modules_path = self.docs_path / "modules"
            if docs_modules_path.exists():
                for module_file in docs_modules_path.glob("*.json"):
                    try:
                        async with aiofiles.open(module_file, 'r') as f:
                            content = await f.read()
                            module_data = json.loads(content)
                        
                        module_name = module_data.get('name', module_file.stem)
                        
                        # Apply module filter
                        if module_filter and module_name != module_filter:
                            continue
                        
                        for func_data in module_data.get('functions', []):
                            func_info = FunctionInfo(
                                name=func_data.get('name', ''),
                                description=func_data.get('description', ''),
                                syntax=func_data.get('syntax', ''),
                                parameters=func_data.get('parameters', []),
                                examples=func_data.get('examples', []),
                                module=module_name
                            )
                            
                            # Apply search filter
                            if search_term:
                                if (search_term.lower() not in func_info.name.lower() and 
                                    search_term.lower() not in (func_info.description or '').lower()):
                                    continue
                            
                            functions.append(func_info)
                            
                    except Exception as e:
                        logger.warning(f"Failed to process module doc {module_file}: {e}")
            
            logger.info(f"Found {len(functions)} functions")
            return functions
            
        except Exception as e:
            logger.error(f"Error getting functions: {e}")
            return []

    async def search_content(self, query: str, limit: int = 50) -> List[SearchResult]:
        """Search across all documentation content"""
        results = []
        query_lower = query.lower()
        
        try:
            # Search in modules and functions
            modules = await self.scan_modules()
            
            for module in modules:
                # Search in module name/description
                if (query_lower in module.name.lower() or 
                    query_lower in (module.description or '').lower()):
                    results.append(SearchResult(
                        id=f"module_{module.id}",
                        name=module.name,
                        description=module.description or '',
                        module=module.name,
                        module_id=module.id,
                        type="module"
                    ))
                
                # Search in module functions
                module_data = await self.get_module_data(module.id)
                if module_data:
                    for func in module_data.get('functions', []):
                        if (query_lower in func.get('name', '').lower() or
                            query_lower in func.get('description', '').lower()):
                            results.append(SearchResult(
                                id=f"function_{module.id}_{func.get('name', '')}",
                                name=func.get('name', ''),
                                description=func.get('description', ''),
                                module=module.name,
                                module_id=module.id,
                                type="function"
                            ))
            
            # Sort by relevance (name matches first, then description matches)
            results.sort(key=lambda x: (
                0 if query_lower in x.name.lower() else 1,
                x.name.lower()
            ))
            
            return results[:limit]
            
        except Exception as e:
            logger.error(f"Error searching content: {e}")
            return []

    async def build_search_index(self) -> List[Dict]:
        """Build search index for client-side search"""
        search_data = []
        
        try:
            modules = await self.scan_modules()
            
            for module in modules:
                # Add module to search index
                search_data.append({
                    "id": f"module_{module.id}",
                    "name": module.name,
                    "description": module.description or '',
                    "module": module.name,
                    "moduleId": module.id,
                    "type": "module"
                })
                
                # Add functions to search index
                module_data = await self.get_module_data(module.id)
                if module_data:
                    for func in module_data.get('functions', []):
                        search_data.append({
                            "id": f"function_{module.id}_{func.get('name', '')}",
                            "name": func.get('name', ''),
                            "description": func.get('description', ''),
                            "module": module.name,
                            "moduleId": module.id,
                            "type": "function"
                        })
            
            logger.info(f"Built search index with {len(search_data)} entries")
            return search_data
            
        except Exception as e:
            logger.error(f"Error building search index: {e}")
            return []

def main():
    """Main entry point"""
    server = DocumentationAPIServer()
    
    host = os.environ.get('API_HOST', '0.0.0.0')
    port = int(os.environ.get('API_PORT', '8091'))
    
    logger.info(f"Starting Documentation API Server on {host}:{port}")
    
    uvicorn.run(
        server.app,
        host=host,
        port=port,
        log_level="info",
        access_log=True
    )

if __name__ == '__main__':
    main()