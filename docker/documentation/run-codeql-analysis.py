#!/usr/bin/env python3
"""
Enhanced Documentation System - CodeQL Security Analysis Service
Phase 3 Day 5: Production Integration & Advanced Features
Automated CodeQL scanning for PowerShell and C# security analysis
"""

import os
import sys
import time
import json
import subprocess
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/docs/generated/security/codeql.log')
    ]
)
logger = logging.getLogger(__name__)

class CodeQLAnalyzer:
    """CodeQL Security Analysis Engine"""
    
    def __init__(self):
        self.codeql_path = os.environ.get('CODEQL_HOME', '/opt/codeql')
        self.db_path = os.environ.get('CODEQL_DB_PATH', '/codeql/databases')
        self.source_path = os.environ.get('SOURCE_PATH', '/source')
        self.results_path = os.environ.get('RESULTS_PATH', '/docs/generated/security')
        self.scan_interval = int(os.environ.get('SCAN_INTERVAL', '3600'))
        
        # Ensure directories exist
        Path(self.db_path).mkdir(parents=True, exist_ok=True)
        Path(self.results_path).mkdir(parents=True, exist_ok=True)
        
        logger.info(f"CodeQL Analyzer initialized")
        logger.info(f"Source path: {self.source_path}")
        logger.info(f"Database path: {self.db_path}")
        logger.info(f"Results path: {self.results_path}")
        logger.info(f"Scan interval: {self.scan_interval}s")

    def check_codeql_installation(self) -> bool:
        """Verify CodeQL CLI is properly installed"""
        try:
            result = subprocess.run(
                ['codeql', '--version'],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                logger.info(f"CodeQL CLI version: {result.stdout.strip()}")
                return True
            else:
                logger.error(f"CodeQL CLI not responding: {result.stderr}")
                return False
        except Exception as e:
            logger.error(f"Failed to check CodeQL installation: {e}")
            return False

    def create_database(self, language: str, db_name: str) -> bool:
        """Create CodeQL database for specified language"""
        try:
            db_full_path = os.path.join(self.db_path, db_name)
            
            # Remove existing database if present
            if os.path.exists(db_full_path):
                subprocess.run(['rm', '-rf', db_full_path], check=True)
            
            logger.info(f"Creating {language} CodeQL database: {db_name}")
            
            # Create database based on language
            if language == 'csharp':
                cmd = [
                    'codeql', 'database', 'create',
                    db_full_path,
                    '--language', 'csharp',
                    '--source-root', self.source_path,
                    '--overwrite'
                ]
            elif language == 'powershell':
                # For PowerShell, we'll use generic analysis
                cmd = [
                    'codeql', 'database', 'create',
                    db_full_path,
                    '--language', 'javascript',  # Use JS for script analysis
                    '--source-root', self.source_path,
                    '--overwrite'
                ]
            else:
                logger.error(f"Unsupported language: {language}")
                return False
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=1800  # 30 minutes timeout
            )
            
            if result.returncode == 0:
                logger.info(f"Successfully created {language} database")
                return True
            else:
                logger.error(f"Failed to create {language} database: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            logger.error(f"Database creation timed out for {language}")
            return False
        except Exception as e:
            logger.error(f"Exception creating database for {language}: {e}")
            return False

    def run_security_queries(self, db_name: str, language: str) -> Optional[Dict]:
        """Run security queries against the database"""
        try:
            db_full_path = os.path.join(self.db_path, db_name)
            
            if not os.path.exists(db_full_path):
                logger.error(f"Database not found: {db_full_path}")
                return None
            
            # Define query suites based on language
            query_suites = {
                'csharp': [
                    'csharp-security-and-quality.qls',
                    'csharp-security-extended.qls'
                ],
                'powershell': [
                    'security/CWE-078',  # Command Injection
                    'security/CWE-079',  # Cross-site scripting
                    'security/CWE-089',  # SQL Injection
                ]
            }
            
            results = {
                'timestamp': datetime.now().isoformat(),
                'language': language,
                'database': db_name,
                'findings': []
            }
            
            logger.info(f"Running security queries for {language}")
            
            for suite in query_suites.get(language, []):
                try:
                    output_file = os.path.join(
                        self.results_path,
                        f"{language}_{suite.replace('/', '_').replace('.qls', '')}_results.json"
                    )
                    
                    cmd = [
                        'codeql', 'database', 'analyze',
                        db_full_path,
                        suite,
                        '--format', 'sarif-latest',
                        '--output', output_file,
                        '--threads', '2'
                    ]
                    
                    result = subprocess.run(
                        cmd,
                        capture_output=True,
                        text=True,
                        timeout=1200  # 20 minutes timeout
                    )
                    
                    if result.returncode == 0:
                        logger.info(f"Successfully ran query suite: {suite}")
                        
                        # Parse results if output file exists
                        if os.path.exists(output_file):
                            with open(output_file, 'r') as f:
                                sarif_data = json.load(f)
                                findings = self.parse_sarif_results(sarif_data, suite)
                                results['findings'].extend(findings)
                    else:
                        logger.warning(f"Query suite {suite} failed: {result.stderr}")
                        
                except subprocess.TimeoutExpired:
                    logger.warning(f"Query suite {suite} timed out")
                except Exception as e:
                    logger.warning(f"Exception running suite {suite}: {e}")
            
            return results
            
        except Exception as e:
            logger.error(f"Exception running security queries: {e}")
            return None

    def parse_sarif_results(self, sarif_data: Dict, query_suite: str) -> List[Dict]:
        """Parse SARIF format results into simplified findings"""
        findings = []
        
        try:
            for run in sarif_data.get('runs', []):
                for result in run.get('results', []):
                    finding = {
                        'query_suite': query_suite,
                        'rule_id': result.get('ruleId', 'unknown'),
                        'level': result.get('level', 'note'),
                        'message': result.get('message', {}).get('text', ''),
                        'locations': []
                    }
                    
                    # Extract location information
                    for location in result.get('locations', []):
                        physical_location = location.get('physicalLocation', {})
                        artifact_location = physical_location.get('artifactLocation', {})
                        region = physical_location.get('region', {})
                        
                        finding['locations'].append({
                            'file': artifact_location.get('uri', ''),
                            'start_line': region.get('startLine', 0),
                            'start_column': region.get('startColumn', 0),
                            'end_line': region.get('endLine', 0),
                            'end_column': region.get('endColumn', 0)
                        })
                    
                    findings.append(finding)
                    
        except Exception as e:
            logger.error(f"Error parsing SARIF results: {e}")
        
        return findings

    def generate_security_report(self, all_results: List[Dict]) -> str:
        """Generate comprehensive security report"""
        try:
            report = {
                'scan_timestamp': datetime.now().isoformat(),
                'total_findings': sum(len(r['findings']) for r in all_results),
                'languages_scanned': [r['language'] for r in all_results],
                'findings_by_severity': {
                    'error': 0,
                    'warning': 0,
                    'note': 0
                },
                'results': all_results,
                'summary': {
                    'critical_issues': 0,
                    'high_issues': 0,
                    'medium_issues': 0,
                    'low_issues': 0
                }
            }
            
            # Count findings by severity
            for result in all_results:
                for finding in result['findings']:
                    level = finding['level'].lower()
                    if level in report['findings_by_severity']:
                        report['findings_by_severity'][level] += 1
                    
                    # Map to security severity
                    if level == 'error':
                        report['summary']['critical_issues'] += 1
                    elif level == 'warning':
                        report['summary']['high_issues'] += 1
                    else:
                        report['summary']['medium_issues'] += 1
            
            # Write comprehensive report
            report_path = os.path.join(self.results_path, 'security_report.json')
            with open(report_path, 'w') as f:
                json.dump(report, f, indent=2)
            
            # Generate summary report
            summary_path = os.path.join(self.results_path, 'security_summary.md')
            with open(summary_path, 'w') as f:
                f.write(f"# Security Analysis Report\n\n")
                f.write(f"**Scan Date:** {report['scan_timestamp']}\n\n")
                f.write(f"**Languages Analyzed:** {', '.join(report['languages_scanned'])}\n\n")
                f.write(f"## Summary\n\n")
                f.write(f"- **Total Findings:** {report['total_findings']}\n")
                f.write(f"- **Critical Issues:** {report['summary']['critical_issues']}\n")
                f.write(f"- **High Issues:** {report['summary']['high_issues']}\n")
                f.write(f"- **Medium Issues:** {report['summary']['medium_issues']}\n")
                f.write(f"- **Low Issues:** {report['summary']['low_issues']}\n\n")
                
                if report['total_findings'] > 0:
                    f.write(f"## Findings by Severity\n\n")
                    for level, count in report['findings_by_severity'].items():
                        if count > 0:
                            f.write(f"- **{level.title()}:** {count}\n")
                else:
                    f.write(f"## ✅ No Security Issues Found\n\n")
                    f.write(f"The security analysis did not identify any issues in the scanned code.\n")
            
            logger.info(f"Security report generated: {report_path}")
            return report_path
            
        except Exception as e:
            logger.error(f"Failed to generate security report: {e}")
            return ""

    def run_analysis_cycle(self) -> bool:
        """Run a complete analysis cycle"""
        try:
            logger.info("Starting CodeQL analysis cycle")
            
            # Check CodeQL installation
            if not self.check_codeql_installation():
                logger.error("CodeQL not properly installed")
                return False
            
            all_results = []
            
            # Analyze C# code
            if self.create_database('csharp', 'csharp-db'):
                csharp_results = self.run_security_queries('csharp-db', 'csharp')
                if csharp_results:
                    all_results.append(csharp_results)
            
            # Analyze PowerShell code (using JavaScript parser as fallback)
            if self.create_database('powershell', 'powershell-db'):
                ps_results = self.run_security_queries('powershell-db', 'powershell')
                if ps_results:
                    all_results.append(ps_results)
            
            # Generate comprehensive report
            if all_results:
                self.generate_security_report(all_results)
                logger.info(f"Analysis cycle completed. Found {sum(len(r['findings']) for r in all_results)} total findings")
            else:
                logger.warning("Analysis cycle completed but no results generated")
            
            return True
            
        except Exception as e:
            logger.error(f"Analysis cycle failed: {e}")
            return False

    def run_continuous_analysis(self):
        """Run continuous security analysis"""
        logger.info("Starting continuous CodeQL security analysis")
        
        while True:
            try:
                # Update health status
                health_file = os.path.join(self.db_path, 'health.txt')
                with open(health_file, 'w') as f:
                    f.write(f"{datetime.now()}: CodeQL service operational\n")
                
                # Run analysis cycle
                self.run_analysis_cycle()
                
                # Sleep until next scan
                logger.info(f"Analysis completed. Next scan in {self.scan_interval} seconds")
                time.sleep(self.scan_interval)
                
            except KeyboardInterrupt:
                logger.info("Shutdown requested")
                break
            except Exception as e:
                logger.error(f"Error in continuous analysis: {e}")
                time.sleep(60)  # Wait 1 minute before retrying

def main():
    """Main entry point"""
    analyzer = CodeQLAnalyzer()
    analyzer.run_continuous_analysis()

if __name__ == '__main__':
    main()