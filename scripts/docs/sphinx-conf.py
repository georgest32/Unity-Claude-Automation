#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sphinx configuration for Unity-Claude-Automation Python Documentation

This file configures Sphinx to generate documentation from Python docstrings
using autodoc, with support for NumPy and Google style docstrings.
"""

import os
import sys
from datetime import datetime

# Add project root to Python path for autodoc
sys.path.insert(0, os.path.abspath('../../../'))
sys.path.insert(0, os.path.abspath('../../'))

# Project information
project = 'Unity-Claude-Automation Python API'
copyright = f'{datetime.now().year}, Unity-Claude-Automation Team'
author = 'Unity-Claude-Automation Team'
release = '1.0.0'
version = '1.0'

# General configuration
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autodoc.typehints',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
    'sphinx.ext.githubpages',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx.ext.mathjax',
    'sphinx_rtd_theme',
    'sphinx.ext.autosummary',
    'sphinx.ext.doctest',
]

# Add any paths that contain templates here
templates_path = ['_templates']

# List of patterns to exclude
exclude_patterns = [
    '_build',
    'Thumbs.db',
    '.DS_Store',
    '**/.venv',
    '**/venv',
    '**/node_modules',
    '**/__pycache__',
    '**/*.pyc',
]

# The suffix of source filenames
source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

# The master toctree document
master_doc = 'index'

# Autodoc configuration
autodoc_default_options = {
    'members': True,
    'member-order': 'bysource',
    'special-members': '__init__',
    'undoc-members': True,
    'exclude-members': '__weakref__',
    'show-inheritance': True,
    'inherited-members': False,
    'private-members': False,
}

# Napoleon settings for NumPy and Google style docstrings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = True
napoleon_include_private_with_doc = False
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = True
napoleon_use_admonition_for_notes = True
napoleon_use_admonition_for_references = False
napoleon_use_ivar = False
napoleon_use_param = True
napoleon_use_rtype = True
napoleon_preprocess_types = False
napoleon_type_aliases = None
napoleon_attr_annotations = True

# Autosummary configuration
autosummary_generate = True
autosummary_generate_overwrite = True

# Mock imports for missing dependencies
autodoc_mock_imports = [
    'numpy',
    'pandas',
    'matplotlib',
    'scipy',
    'sklearn',
    'torch',
    'tensorflow',
    'langchain',
    'langgraph',
    'autogen',
]

# Intersphinx configuration
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'numpy': ('https://numpy.org/doc/stable/', None),
    'pandas': ('https://pandas.pydata.org/docs/', None),
}

# HTML output options
html_theme = 'sphinx_rtd_theme'

html_theme_options = {
    'logo_only': False,
    'display_version': True,
    'prev_next_buttons_location': 'bottom',
    'style_external_links': True,
    'vcs_pageview_mode': '',
    'style_nav_header_background': '#2980b9',
    # Toc options
    'collapse_navigation': True,
    'sticky_navigation': True,
    'navigation_depth': 4,
    'includehidden': True,
    'titles_only': False,
}

# Add any paths that contain custom static files
html_static_path = ['_static']

# Custom CSS
html_css_files = [
    'custom.css',
]

# Output file base name for HTML help builder
htmlhelp_basename = 'UnityClaudeAutomationDoc'

# LaTeX output options
latex_elements = {
    'papersize': 'letterpaper',
    'pointsize': '10pt',
    'preamble': '',
    'figure_align': 'htbp',
}

latex_documents = [
    (master_doc, 'UnityClaudeAutomation.tex',
     'Unity-Claude-Automation Documentation',
     'Unity-Claude-Automation Team', 'manual'),
]

# Man page output
man_pages = [
    (master_doc, 'unityclaudeautomation',
     'Unity-Claude-Automation Documentation',
     [author], 1)
]

# Texinfo output
texinfo_documents = [
    (master_doc, 'UnityClaudeAutomation',
     'Unity-Claude-Automation Documentation',
     author, 'UnityClaudeAutomation',
     'Multi-agent repository documentation system.',
     'Miscellaneous'),
]

# Epub output
epub_title = project
epub_exclude_files = ['search.html']

# Todo extension settings
todo_include_todos = True

# Coverage extension settings
coverage_ignore_modules = []
coverage_ignore_functions = []
coverage_ignore_classes = []
coverage_ignore_pyobjects = []

# Custom setup function
def setup(app):
    """Custom Sphinx setup function."""
    app.add_css_file('custom.css')
    app.add_config_value('recommonmark_config', {
        'enable_auto_toc_tree': True,
        'auto_toc_tree_section': 'Contents',
        'enable_math': True,
        'enable_inline_math': True,
        'enable_eval_rst': True,
    }, True)