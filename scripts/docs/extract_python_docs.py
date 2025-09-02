#!/usr/bin/env python3
"""
Python Documentation Extractor

Extracts documentation from Python files including docstrings,
function signatures, and class information.
"""

import ast
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional
import argparse
import inspect


class PythonDocExtractor:
    """Extracts documentation from Python source files."""
    
    def __init__(self):
        self.documentation = {
            'generated_at': datetime.now().isoformat(),
            'modules': [],
            'classes': [],
            'functions': [],
            'files': []
        }
    
    def extract_docstring(self, node: ast.AST) -> Optional[str]:
        """Extract docstring from an AST node."""
        if not isinstance(node, (ast.FunctionDef, ast.ClassDef, ast.Module)):
            return None
        
        if node.body and isinstance(node.body[0], ast.Expr):
            if isinstance(node.body[0].value, ast.Str):
                return node.body[0].value.s
            elif isinstance(node.body[0].value, ast.Constant):
                return node.body[0].value.value
        return None
    
    def extract_function_info(self, node: ast.FunctionDef, filepath: str, 
                            class_name: Optional[str] = None) -> Dict[str, Any]:
        """Extract information from a function definition."""
        func_info = {
            'name': node.name,
            'file_path': filepath,
            'line_number': node.lineno,
            'column_offset': node.col_offset,
            'docstring': self.extract_docstring(node),
            'parameters': [],
            'returns': None,
            'decorators': [],
            'is_async': isinstance(node, ast.AsyncFunctionDef),
            'class_name': class_name
        }
        
        # Extract parameters
        for arg in node.args.args:
            param_info = {
                'name': arg.arg,
                'annotation': None,
                'default': None
            }
            
            if arg.annotation:
                param_info['annotation'] = ast.unparse(arg.annotation)
            
            func_info['parameters'].append(param_info)
        
        # Handle default values
        defaults = node.args.defaults
        if defaults:
            offset = len(func_info['parameters']) - len(defaults)
            for i, default in enumerate(defaults):
                if default:
                    func_info['parameters'][offset + i]['default'] = ast.unparse(default)
        
        # Extract return type
        if node.returns:
            func_info['returns'] = ast.unparse(node.returns)
        
        # Extract decorators
        for decorator in node.decorator_list:
            if isinstance(decorator, ast.Name):
                func_info['decorators'].append(decorator.id)
            elif isinstance(decorator, ast.Call) and isinstance(decorator.func, ast.Name):
                func_info['decorators'].append(decorator.func.id)
        
        return func_info
    
    def extract_class_info(self, node: ast.ClassDef, filepath: str) -> Dict[str, Any]:
        """Extract information from a class definition."""
        class_info = {
            'name': node.name,
            'file_path': filepath,
            'line_number': node.lineno,
            'column_offset': node.col_offset,
            'docstring': self.extract_docstring(node),
            'bases': [],
            'methods': [],
            'attributes': [],
            'decorators': []
        }
        
        # Extract base classes
        for base in node.bases:
            if isinstance(base, ast.Name):
                class_info['bases'].append(base.id)
            else:
                class_info['bases'].append(ast.unparse(base))
        
        # Extract decorators
        for decorator in node.decorator_list:
            if isinstance(decorator, ast.Name):
                class_info['decorators'].append(decorator.id)
            elif isinstance(decorator, ast.Call) and isinstance(decorator.func, ast.Name):
                class_info['decorators'].append(decorator.func.id)
        
        # Extract methods and attributes
        for item in node.body:
            if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                method_info = self.extract_function_info(item, filepath, node.name)
                class_info['methods'].append(method_info)
            elif isinstance(item, ast.Assign):
                for target in item.targets:
                    if isinstance(target, ast.Name):
                        attr_info = {
                            'name': target.id,
                            'line_number': item.lineno,
                            'value': ast.unparse(item.value) if item.value else None
                        }
                        class_info['attributes'].append(attr_info)
        
        return class_info
    
    def extract_module_info(self, filepath: str) -> Dict[str, Any]:
        """Extract information from a Python module file."""
        module_info = {
            'file_path': filepath,
            'name': Path(filepath).stem,
            'docstring': None,
            'imports': [],
            'functions': [],
            'classes': [],
            'constants': []
        }
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content, filename=filepath)
            module_info['docstring'] = self.extract_docstring(tree)
            
            for node in ast.walk(tree):
                # Extract imports
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        module_info['imports'].append({
                            'module': alias.name,
                            'alias': alias.asname,
                            'type': 'import'
                        })
                elif isinstance(node, ast.ImportFrom):
                    for alias in node.names:
                        module_info['imports'].append({
                            'module': node.module,
                            'name': alias.name,
                            'alias': alias.asname,
                            'type': 'from'
                        })
            
            # Extract top-level elements
            for node in tree.body:
                if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    func_info = self.extract_function_info(node, filepath)
                    module_info['functions'].append(func_info)
                    self.documentation['functions'].append(func_info)
                elif isinstance(node, ast.ClassDef):
                    class_info = self.extract_class_info(node, filepath)
                    module_info['classes'].append(class_info)
                    self.documentation['classes'].append(class_info)
                elif isinstance(node, ast.Assign):
                    # Extract module-level constants
                    for target in node.targets:
                        if isinstance(target, ast.Name) and target.id.isupper():
                            const_info = {
                                'name': target.id,
                                'value': ast.unparse(node.value) if node.value else None,
                                'line_number': node.lineno
                            }
                            module_info['constants'].append(const_info)
            
            return module_info
            
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
            return module_info
    
    def process_directory(self, directory: str, recursive: bool = True) -> None:
        """Process all Python files in a directory."""
        path = Path(directory)
        
        if recursive:
            python_files = path.rglob('*.py')
        else:
            python_files = path.glob('*.py')
        
        for filepath in python_files:
            if '__pycache__' not in str(filepath):
                print(f"Processing: {filepath}")
                self.documentation['files'].append(str(filepath))
                module_info = self.extract_module_info(str(filepath))
                self.documentation['modules'].append(module_info)
    
    def process_file(self, filepath: str) -> None:
        """Process a single Python file."""
        print(f"Processing: {filepath}")
        self.documentation['files'].append(filepath)
        module_info = self.extract_module_info(filepath)
        self.documentation['modules'].append(module_info)
    
    def generate_markdown(self) -> str:
        """Generate markdown documentation."""
        lines = []
        lines.append("# Python Documentation")
        lines.append("")
        lines.append(f"Generated: {self.documentation['generated_at']}")
        lines.append("")
        
        # Modules section
        if self.documentation['modules']:
            lines.append("## Modules")
            lines.append("")
            
            for module in self.documentation['modules']:
                lines.append(f"### {module['name']}")
                lines.append("")
                
                if module['docstring']:
                    lines.append(module['docstring'])
                    lines.append("")
                
                lines.append(f"**File:** {module['file_path']}")
                lines.append("")
                
                if module['imports']:
                    lines.append("**Imports:**")
                    for imp in module['imports']:
                        if imp['type'] == 'import':
                            lines.append(f"- import {imp['module']}")
                        else:
                            lines.append(f"- from {imp['module']} import {imp['name']}")
                    lines.append("")
        
        # Classes section
        if self.documentation['classes']:
            lines.append("## Classes")
            lines.append("")
            
            for cls in self.documentation['classes']:
                lines.append(f"### {cls['name']}")
                lines.append("")
                
                if cls['docstring']:
                    lines.append(cls['docstring'])
                    lines.append("")
                
                if cls['bases']:
                    lines.append(f"**Inherits from:** {', '.join(cls['bases'])}")
                    lines.append("")
                
                if cls['methods']:
                    lines.append("**Methods:**")
                    for method in cls['methods']:
                        params = ', '.join([p['name'] for p in method['parameters']])
                        lines.append(f"- `{method['name']}({params})`")
                        if method['docstring']:
                            lines.append(f"  - {method['docstring'].split('\\n')[0]}")
                    lines.append("")
                
                lines.append(f"**Source:** {cls['file_path']}:{cls['line_number']}")
                lines.append("")
                lines.append("---")
                lines.append("")
        
        # Functions section
        if self.documentation['functions']:
            # Filter out class methods
            standalone_funcs = [f for f in self.documentation['functions'] 
                              if not f.get('class_name')]
            
            if standalone_funcs:
                lines.append("## Functions")
                lines.append("")
                
                for func in standalone_funcs:
                    lines.append(f"### {func['name']}")
                    lines.append("")
                    
                    if func['docstring']:
                        lines.append(func['docstring'])
                        lines.append("")
                    
                    if func['parameters']:
                        lines.append("**Parameters:**")
                        for param in func['parameters']:
                            param_str = f"- **{param['name']}**"
                            if param['annotation']:
                                param_str += f" ({param['annotation']})"
                            if param['default']:
                                param_str += f" = {param['default']}"
                            lines.append(param_str)
                        lines.append("")
                    
                    if func['returns']:
                        lines.append(f"**Returns:** {func['returns']}")
                        lines.append("")
                    
                    lines.append(f"**Source:** {func['file_path']}:{func['line_number']}")
                    lines.append("")
                    lines.append("---")
                    lines.append("")
        
        return '\n'.join(lines)
    
    def save_json(self, filepath: str) -> None:
        """Save documentation as JSON."""
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(self.documentation, f, indent=2, default=str)
        print(f"JSON documentation saved to: {filepath}")
    
    def save_markdown(self, filepath: str) -> None:
        """Save documentation as Markdown."""
        markdown = self.generate_markdown()
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(markdown)
        print(f"Markdown documentation saved to: {filepath}")


def main():
    parser = argparse.ArgumentParser(description='Extract Python documentation')
    parser.add_argument('path', help='Path to Python file or directory')
    parser.add_argument('--output-format', choices=['json', 'markdown', 'both'],
                       default='both', help='Output format')
    parser.add_argument('--recursive', action='store_true',
                       help='Recursively process directories')
    parser.add_argument('--output-dir', default='.',
                       help='Output directory for documentation files')
    
    args = parser.parse_args()
    
    extractor = PythonDocExtractor()
    
    # Process input path
    path = Path(args.path)
    if path.is_file():
        extractor.process_file(str(path))
    elif path.is_dir():
        extractor.process_directory(str(path), args.recursive)
    else:
        print(f"Error: {args.path} is not a valid file or directory")
        sys.exit(1)
    
    # Generate output
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if args.output_format in ['json', 'both']:
        json_path = output_dir / f"python_docs_{timestamp}.json"
        extractor.save_json(str(json_path))
    
    if args.output_format in ['markdown', 'both']:
        md_path = output_dir / f"python_docs_{timestamp}.md"
        extractor.save_markdown(str(md_path))
    
    # Print summary
    print("")
    print("Documentation extraction complete!")
    print(f"Processed {len(extractor.documentation['modules'])} modules")
    print(f"Found {len(extractor.documentation['classes'])} classes")
    print(f"Found {len(extractor.documentation['functions'])} functions")


if __name__ == '__main__':
    main()