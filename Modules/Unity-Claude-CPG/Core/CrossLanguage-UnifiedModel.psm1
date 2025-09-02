#Requires -Version 5.1
<#
.SYNOPSIS
    Cross-Language Unified Model for Code Property Graph integration.

.DESCRIPTION
    Provides unified representation of code constructs across multiple programming languages,
    enabling seamless cross-language analysis and relationship mapping.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 4 - Full Day Implementation
    Created: 2025-08-28
#>

# Module dependencies - must use absolute paths or remove
# For now, we'll define necessary types locally to avoid dependency issues

# Unified node types that transcend language boundaries
enum UnifiedNodeType {
    # Structural Elements
    Project = 0
    Namespace = 1
    Module = 2
    Package = 3
    
    # Type Definitions
    ClassDefinition = 10
    InterfaceDefinition = 11
    StructDefinition = 12
    EnumDefinition = 13
    TypeAlias = 14
    
    # Callable Elements
    FunctionDefinition = 20
    MethodDefinition = 21
    ConstructorDefinition = 22
    PropertyDefinition = 23
    FieldDefinition = 24
    
    # Control Flow
    ConditionalBlock = 30
    LoopBlock = 31
    TryBlock = 32
    CatchBlock = 33
    
    # Data Elements
    VariableDeclaration = 40
    ParameterDeclaration = 41
    ConstantDeclaration = 42
    
    # References and Usage
    FunctionCall = 50
    MethodCall = 51
    VariableReference = 52
    TypeReference = 53
    
    # Import/Export
    ImportStatement = 60
    ExportStatement = 61
    UsingStatement = 62
    
    # Language-Specific
    Decorator = 70
    Attribute = 71
    Annotation = 72
    Comment = 73
    Documentation = 74
}

# Unified relationship types
enum UnifiedRelationType {
    # Structural Relationships  
    Contains = 0
    BelongsTo = 1
    Defines = 2
    
    # Inheritance Relationships
    Inherits = 10
    Implements = 11
    Extends = 12
    
    # Usage Relationships
    Calls = 20
    References = 21
    Uses = 22
    Returns = 23
    
    # Data Flow Relationships
    Reads = 30
    Writes = 31
    Modifies = 32
    
    # Import Relationships
    Imports = 40
    Exports = 41
    Depends = 42
    
    # Cross-Language Relationships
    Equivalent = 50
    Similar = 51
    Mapped = 52
}

# Language mapping confidence levels
enum MappingConfidence {
    Exact = 0      # Perfect 1:1 mapping
    High = 1       # Very similar constructs
    Medium = 2     # Similar with minor differences  
    Low = 3        # Conceptually similar
    None = 4       # No equivalent
}

# Unified node class
class UnifiedNode {
    [string]$Id
    [UnifiedNodeType]$Type
    [string]$Name
    [string]$FullyQualifiedName
    [string]$Language
    [string]$OriginalType  # Language-specific type
    [hashtable]$Properties
    [hashtable]$LanguageSpecificData
    [hashtable]$Position  # @{File, StartLine, EndLine, StartColumn, EndColumn}
    [MappingConfidence]$MappingConfidence
    [string[]]$Aliases
    
    UnifiedNode() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.LanguageSpecificData = @{}
        $this.Position = @{}
        $this.Aliases = @()
        $this.MappingConfidence = [MappingConfidence]::High
    }
    
    UnifiedNode([UnifiedNodeType]$type, [string]$name, [string]$language) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.Name = $name
        $this.Language = $language
        $this.Properties = @{}
        $this.LanguageSpecificData = @{}
        $this.Position = @{}
        $this.Aliases = @()
        $this.MappingConfidence = [MappingConfidence]::High
    }
    
    [string] GetDisplayName() {
        if ($this.FullyQualifiedName) {
            return $this.FullyQualifiedName
        }
        return "$($this.Language):$($this.Name)"
    }
    
    [hashtable] GetMetadata() {
        return @{
            Id = $this.Id
            Type = $this.Type.ToString()
            Name = $this.Name
            DisplayName = $this.GetDisplayName()
            Language = $this.Language
            OriginalType = $this.OriginalType
            Position = $this.Position
            MappingConfidence = $this.MappingConfidence.ToString()
            Properties = $this.Properties
        }
    }
    
    [bool] IsEquivalentTo([UnifiedNode]$other) {
        # Check if two nodes represent the same logical construct
        if ($this.Type -ne $other.Type) {
            return $false
        }
        
        if ($this.Name -eq $other.Name -or $other.Name -in $this.Aliases -or $this.Name -in $other.Aliases) {
            return $true
        }
        
        # Check normalized names
        $thisNormalized = $this.Name -replace '[_-]', '' -replace '([a-z])([A-Z])', '$1$2'
        $otherNormalized = $other.Name -replace '[_-]', '' -replace '([a-z])([A-Z])', '$1$2'
        
        return $thisNormalized -eq $otherNormalized
    }
}

# Unified relationship class
class UnifiedRelation {
    [string]$Id
    [UnifiedRelationType]$Type
    [string]$SourceId
    [string]$TargetId
    [string]$Description
    [hashtable]$Properties
    [double]$Weight
    [MappingConfidence]$Confidence
    [string[]]$SourceLanguages  # Languages where this relationship exists
    
    UnifiedRelation() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Weight = 1.0
        $this.Confidence = [MappingConfidence]::High
        $this.SourceLanguages = @()
    }
    
    UnifiedRelation([UnifiedRelationType]$type, [string]$sourceId, [string]$targetId) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.Properties = @{}
        $this.Weight = 1.0
        $this.Confidence = [MappingConfidence]::High
        $this.SourceLanguages = @()
    }
    
    [bool] IsCrossLanguage() {
        return $this.SourceLanguages.Count -gt 1
    }
    
    [hashtable] GetMetadata() {
        return @{
            Id = $this.Id
            Type = $this.Type.ToString()
            SourceId = $this.SourceId
            TargetId = $this.TargetId
            Description = $this.Description
            Weight = $this.Weight
            Confidence = $this.Confidence.ToString()
            IsCrossLanguage = $this.IsCrossLanguage()
            SourceLanguages = $this.SourceLanguages
            Properties = $this.Properties
        }
    }
}

# Language mapper class
class LanguageMapper {
    [hashtable]$LanguageMappings
    [hashtable]$TypeMappings
    [hashtable]$PatternMappings
    
    LanguageMapper() {
        $this.InitializeMappings()
    }
    
    [void] InitializeMappings() {
        # Initialize language construct mappings
        $this.LanguageMappings = @{
            # Class-like constructs
            ClassDefinition = @{
                'csharp' = @('class', 'struct', 'record')
                'python' = @('class')
                'javascript' = @('class')
                'typescript' = @('class', 'interface')
            }
            
            # Function-like constructs
            FunctionDefinition = @{
                'csharp' = @('method', 'function')
                'python' = @('def', 'function')
                'javascript' = @('function', 'arrow function')
                'typescript' = @('function', 'method')
            }
            
            # Module/Namespace constructs
            Namespace = @{
                'csharp' = @('namespace')
                'python' = @('module', '__init__')
                'javascript' = @('module')
                'typescript' = @('namespace', 'module')
            }
            
            # Import constructs
            ImportStatement = @{
                'csharp' = @('using')
                'python' = @('import', 'from')
                'javascript' = @('import', 'require')
                'typescript' = @('import')
            }
        }
        
        # Initialize type mappings
        $this.TypeMappings = @{
            # Primitive types
            'string' = @{
                'csharp' = 'string'
                'python' = 'str'
                'javascript' = 'string'
                'typescript' = 'string'
            }
            'integer' = @{
                'csharp' = 'int'
                'python' = 'int'
                'javascript' = 'number'
                'typescript' = 'number'
            }
            'boolean' = @{
                'csharp' = 'bool'
                'python' = 'bool'
                'javascript' = 'boolean'
                'typescript' = 'boolean'
            }
            'array' = @{
                'csharp' = 'Array', 'List', '[]'
                'python' = 'list'
                'javascript' = 'Array', '[]'
                'typescript' = 'Array', '[]'
            }
        }
        
        # Initialize pattern mappings for common patterns
        $this.PatternMappings = @{
            'constructor' = @{
                'csharp' = 'public\s+ClassName\s*\('
                'python' = '__init__\s*\('
                'javascript' = 'constructor\s*\('
                'typescript' = 'constructor\s*\('
            }
            'property' = @{
                'csharp' = '{\s*get\s*;\s*set\s*;?\s*}'
                'python' = '@property'
                'javascript' = 'get\s+\w+|set\s+\w+'
                'typescript' = 'get\s+\w+|set\s+\w+'
            }
        }
    }
    
    [UnifiedNodeType] MapToUnifiedType([string]$originalType, [string]$language) {
        # Map language-specific constructs to unified types
        foreach ($unifiedType in $this.LanguageMappings.Keys) {
            $languageConstructs = $this.LanguageMappings[$unifiedType][$language]
            if ($languageConstructs -and $originalType -in $languageConstructs) {
                try {
                    return [Enum]::Parse([UnifiedNodeType], $unifiedType)
                }
                catch {
                    Write-Verbose "Failed to parse enum value: $unifiedType"
                }
            }
        }
        
        # Default mapping based on common patterns
        switch -Regex ($originalType.ToLower()) {
            'class|struct|record' { return [UnifiedNodeType]::ClassDefinition }
            'interface|protocol' { return [UnifiedNodeType]::InterfaceDefinition }
            'function|method|def' { return [UnifiedNodeType]::FunctionDefinition }
            'namespace|module|package' { return [UnifiedNodeType]::Namespace }
            'import|using|require' { return [UnifiedNodeType]::ImportStatement }
            'variable|var|let|const' { return [UnifiedNodeType]::VariableDeclaration }
            default { return [UnifiedNodeType]::VariableReference }
        }
        
        # Explicit return to satisfy PowerShell compiler
        return [UnifiedNodeType]::VariableReference
    }
    
    [MappingConfidence] GetMappingConfidence([string]$originalType, [string]$language, [UnifiedNodeType]$unifiedType) {
        $languageConstructs = $this.LanguageMappings[$unifiedType.ToString()][$language]
        
        if (-not $languageConstructs) {
            return [MappingConfidence]::None
        }
        
        if ($originalType -in $languageConstructs) {
            return [MappingConfidence]::Exact
        }
        
        # Check for similar patterns
        foreach ($construct in $languageConstructs) {
            if ($originalType -match $construct -or $construct -match $originalType) {
                return [MappingConfidence]::High
            }
        }
        
        return [MappingConfidence]::Low
    }
    
    [string] NormalizeTypeName([string]$typeName, [string]$language) {
        # Normalize type names to common format
        $normalized = $typeName
        
        # Remove language-specific prefixes/suffixes
        switch ($language.ToLower()) {
            'csharp' {
                $normalized = $normalized -replace 'System\.', ''
                $normalized = $normalized -replace 'I([A-Z])', '$1'  # Remove interface prefix
            }
            'python' {
                $normalized = $normalized -replace '__', ''
                $normalized = $normalized -replace '_([a-z])', { $_.Groups[1].Value.ToUpper() }
            }
            'javascript' {
                $normalized = $normalized -replace 'function\s+', ''
            }
            'typescript' {
                $normalized = $normalized -replace ':\s*\w+', ''  # Remove type annotations
            }
        }
        
        # Convert to PascalCase
        $normalized = (Get-Culture).TextInfo.ToTitleCase($normalized.ToLower())
        $normalized = $normalized -replace '[^a-zA-Z0-9]', ''
        
        return $normalized
    }
}

# Node normalizer class
class NodeNormalizer {
    [LanguageMapper]$Mapper
    
    NodeNormalizer() {
        $this.Mapper = [LanguageMapper]::new()
    }
    
    [UnifiedNode] NormalizeNode([object]$originalNode) {
        # Create unified node from language-specific node
        $unifiedType = $this.Mapper.MapToUnifiedType($originalNode.Type.ToString(), $originalNode.Language)
        $normalizedName = $this.Mapper.NormalizeTypeName($originalNode.Text, $originalNode.Language)
        
        $unifiedNode = [UnifiedNode]::new($unifiedType, $normalizedName, $originalNode.Language)
        $unifiedNode.OriginalType = $originalNode.Type.ToString()
        $unifiedNode.MappingConfidence = $this.Mapper.GetMappingConfidence($originalNode.Type.ToString(), $originalNode.Language, $unifiedType)
        
        # Copy position information
        if ($originalNode.StartPosition) {
            $unifiedNode.Position = @{
                StartLine = $originalNode.StartPosition.Line
                StartColumn = $originalNode.StartPosition.Column
                EndLine = $originalNode.EndPosition.Line
                EndColumn = $originalNode.EndPosition.Column
            }
        }
        
        # Copy properties
        if ($originalNode.Properties) {
            $unifiedNode.Properties = $originalNode.Properties.Clone()
        }
        
        # Store language-specific data
        $unifiedNode.LanguageSpecificData = @{
            OriginalNode = $originalNode
            CSTNodeType = $originalNode.Type.ToString()
            ParsedText = $originalNode.Text
        }
        
        return $unifiedNode
    }
    
    [UnifiedNode[]] NormalizeNodeCollection([object[]]$nodes) {
        $unifiedNodes = @()
        foreach ($node in $nodes) {
            $unifiedNodes += $this.NormalizeNode($node)
        }
        return $unifiedNodes
    }
    
    [string] GenerateFullyQualifiedName([UnifiedNode]$node, [hashtable]$namespaceContext = @{}) {
        $parts = @()
        
        # Add namespace/module context
        if ($namespaceContext.ContainsKey($node.Language)) {
            $parts += $namespaceContext[$node.Language]
        }
        
        # Add node name
        $parts += $node.Name
        
        return ($parts -join '.')
    }
}

# Relationship resolver class
class RelationshipResolver {
    [LanguageMapper]$Mapper
    
    RelationshipResolver() {
        $this.Mapper = [LanguageMapper]::new()
    }
    
    [UnifiedRelation[]] ResolveRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        # Create lookup dictionary for efficient node finding
        $nodeDict = @{}
        foreach ($node in $nodes) {
            $nodeDict[$node.Id] = $node
        }
        
        # Resolve various types of relationships
        $relationships += $this.ResolveContainmentRelationships($nodes)
        $relationships += $this.ResolveInheritanceRelationships($nodes)
        $relationships += $this.ResolveCallRelationships($nodes)
        $relationships += $this.ResolveImportRelationships($nodes)
        $relationships += $this.ResolveEquivalencyRelationships($nodes)
        
        return $relationships
    }
    
    [UnifiedRelation[]] ResolveContainmentRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        # Group nodes by namespace/module
        $namespaceGroups = $nodes | Group-Object { 
            $this.ExtractNamespace($_.Name, $_.Language)
        }
        
        foreach ($group in $namespaceGroups) {
            $namespace = $group.Name
            $containedNodes = $group.Group
            
            # Find or create namespace node
            $namespaceNode = $containedNodes | Where-Object { 
                $_.Type -eq [UnifiedNodeType]::Namespace -and $_.Name -eq $namespace 
            } | Select-Object -First 1
            
            if ($namespaceNode) {
                foreach ($node in $containedNodes) {
                    if ($node.Id -ne $namespaceNode.Id) {
                        $relation = [UnifiedRelation]::new([UnifiedRelationType]::Contains, $namespaceNode.Id, $node.Id)
                        $relation.Description = "$namespace contains $($node.Name)"
                        $relationships += $relation
                    }
                }
            }
        }
        
        return $relationships
    }
    
    [UnifiedRelation[]] ResolveInheritanceRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        foreach ($node in $nodes) {
            if ($node.Properties.ContainsKey('Inherits')) {
                $parentName = $node.Properties['Inherits']
                $parentNode = $nodes | Where-Object { $_.Name -eq $parentName } | Select-Object -First 1
                
                if ($parentNode) {
                    $relation = [UnifiedRelation]::new([UnifiedRelationType]::Inherits, $node.Id, $parentNode.Id)
                    $relation.Description = "$($node.Name) inherits from $($parentNode.Name)"
                    $relationships += $relation
                }
            }
            
            if ($node.Properties.ContainsKey('Implements')) {
                $interfaceName = $node.Properties['Implements']
                $interfaceNode = $nodes | Where-Object { $_.Name -eq $interfaceName } | Select-Object -First 1
                
                if ($interfaceNode) {
                    $relation = [UnifiedRelation]::new([UnifiedRelationType]::Implements, $node.Id, $interfaceNode.Id)
                    $relation.Description = "$($node.Name) implements $($interfaceNode.Name)"
                    $relationships += $relation
                }
            }
        }
        
        return $relationships
    }
    
    [UnifiedRelation[]] ResolveCallRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        # This would be enhanced with actual call graph data
        # For now, create placeholder relationships based on naming patterns
        
        $functions = $nodes | Where-Object { $_.Type -eq [UnifiedNodeType]::FunctionDefinition }
        
        foreach ($func in $functions) {
            # Look for potential call relationships in language-specific data
            if ($func.LanguageSpecificData.ContainsKey('CallTargets')) {
                $callTargets = $func.LanguageSpecificData['CallTargets']
                
                foreach ($target in $callTargets) {
                    $targetNode = $functions | Where-Object { $_.Name -eq $target } | Select-Object -First 1
                    
                    if ($targetNode) {
                        $relation = [UnifiedRelation]::new([UnifiedRelationType]::Calls, $func.Id, $targetNode.Id)
                        $relation.Description = "$($func.Name) calls $($targetNode.Name)"
                        $relationships += $relation
                    }
                }
            }
        }
        
        return $relationships
    }
    
    [UnifiedRelation[]] ResolveImportRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        $imports = $nodes | Where-Object { $_.Type -eq [UnifiedNodeType]::ImportStatement }
        
        foreach ($import in $imports) {
            # Extract imported module/namespace
            $importedName = $this.ExtractImportTarget($import)
            
            if ($importedName) {
                $importedNode = $nodes | Where-Object { 
                    $_.Name -eq $importedName -or $_.FullyQualifiedName -eq $importedName 
                } | Select-Object -First 1
                
                if ($importedNode) {
                    $relation = [UnifiedRelation]::new([UnifiedRelationType]::Imports, $import.Id, $importedNode.Id)
                    $relation.Description = "Imports $importedName"
                    $relationships += $relation
                }
            }
        }
        
        return $relationships
    }
    
    [UnifiedRelation[]] ResolveEquivalencyRelationships([UnifiedNode[]]$nodes) {
        $relationships = @()
        
        # Group nodes by type
        $typeGroups = $nodes | Group-Object Type
        
        foreach ($group in $typeGroups) {
            $nodesOfType = $group.Group
            
            # Find equivalent nodes across languages
            for ($i = 0; $i -lt $nodesOfType.Count; $i++) {
                for ($j = $i + 1; $j -lt $nodesOfType.Count; $j++) {
                    $node1 = $nodesOfType[$i]
                    $node2 = $nodesOfType[$j]
                    
                    if ($node1.Language -ne $node2.Language -and $node1.IsEquivalentTo($node2)) {
                        $relation = [UnifiedRelation]::new([UnifiedRelationType]::Equivalent, $node1.Id, $node2.Id)
                        $relation.Description = "Cross-language equivalent: $($node1.Language).$($node1.Name) ≡ $($node2.Language).$($node2.Name)"
                        $relation.SourceLanguages = @($node1.Language, $node2.Language)
                        $relationships += $relation
                    }
                }
            }
        }
        
        return $relationships
    }
    
    [string] ExtractNamespace([string]$name, [string]$language) {
        # Extract namespace from fully qualified name
        $parts = $name -split '\.'
        if ($parts.Count -gt 1) {
            return ($parts[0..($parts.Count - 2)] -join '.')
        }
        return ""
    }
    
    [string] ExtractImportTarget([UnifiedNode]$importNode) {
        # Extract the target of an import statement from language-specific data
        if ($importNode.LanguageSpecificData.ContainsKey('ParsedText')) {
            $text = $importNode.LanguageSpecificData['ParsedText']
            
            # Simple extraction patterns
            switch ($importNode.Language.ToLower()) {
                'csharp' {
                    if ($text -match 'using\s+([^;]+)') {
                        return $matches[1].Trim()
                    }
                }
                'python' {
                    if ($text -match 'import\s+([^\s;]+)') {
                        return $matches[1].Trim()
                    }
                    if ($text -match 'from\s+([^\s]+)\s+import') {
                        return $matches[1].Trim()
                    }
                }
                'javascript' {
                    if ($text -match "import.+from\s+[`"']([^`"']+)[`"']") {
                        return $matches[1].Trim()
                    }
                    if ($text -match "require\([`"']([^`"']+)[`"']\)") {
                        return $matches[1].Trim()
                    }
                }
            }
        }
        
        return $null
    }
}

# Main unified model functions
function New-UnifiedCPG {
    <#
    .SYNOPSIS
        Creates a new unified CPG from multiple language-specific CPGs
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$LanguageGraphs,  # @{'csharp' = $csharpCPG, 'python' = $pythonCPG}
        
        [string]$Name = "UnifiedCPG"
    )
    
    $normalizer = [NodeNormalizer]::new()
    $resolver = [RelationshipResolver]::new()
    
    $allUnifiedNodes = @()
    $allUnifiedRelations = @()
    
    # Normalize nodes from each language
    foreach ($language in $LanguageGraphs.Keys) {
        $cpg = $LanguageGraphs[$language]
        
        # Extract CST nodes (this would be adapted based on actual CPG structure)
        $cstNodes = $cpg.Nodes.Values
        
        $unifiedNodes = $normalizer.NormalizeNodeCollection($cstNodes)
        $allUnifiedNodes += $unifiedNodes
        
        Write-Verbose "Normalized $($unifiedNodes.Count) nodes from $language"
    }
    
    # Resolve relationships
    $relationships = $resolver.ResolveRelationships($allUnifiedNodes)
    $allUnifiedRelations += $relationships
    
    Write-Verbose "Resolved $($relationships.Count) unified relationships"
    
    # Create unified CPG structure
    $unifiedCPG = @{
        Name = $Name
        Nodes = @{}
        Relations = @{}
        LanguageIndex = @{}
        TypeIndex = @{}
        CreatedAt = Get-Date
    }
    
    # Index nodes
    foreach ($node in $allUnifiedNodes) {
        $unifiedCPG.Nodes[$node.Id] = $node
        
        # Language index
        if (-not $unifiedCPG.LanguageIndex.ContainsKey($node.Language)) {
            $unifiedCPG.LanguageIndex[$node.Language] = @()
        }
        $unifiedCPG.LanguageIndex[$node.Language] += $node.Id
        
        # Type index
        $typeKey = $node.Type.ToString()
        if (-not $unifiedCPG.TypeIndex.ContainsKey($typeKey)) {
            $unifiedCPG.TypeIndex[$typeKey] = @()
        }
        $unifiedCPG.TypeIndex[$typeKey] += $node.Id
    }
    
    # Index relations
    foreach ($relation in $allUnifiedRelations) {
        $unifiedCPG.Relations[$relation.Id] = $relation
    }
    
    return $unifiedCPG
}

function Get-UnifiedNodes {
    <#
    .SYNOPSIS
        Queries unified CPG for nodes matching criteria
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$UnifiedCPG,
        
        [UnifiedNodeType]$Type,
        [string]$Language,
        [string]$Name,
        [string]$Pattern
    )
    
    $results = $UnifiedCPG.Nodes.Values
    
    if ($Type) {
        $results = $results | Where-Object { $_.Type -eq $Type }
    }
    
    if ($Language) {
        $results = $results | Where-Object { $_.Language -eq $Language }
    }
    
    if ($Name) {
        $results = $results | Where-Object { $_.Name -eq $Name -or $_.FullyQualifiedName -eq $Name }
    }
    
    if ($Pattern) {
        $results = $results | Where-Object { $_.Name -match $Pattern -or $_.FullyQualifiedName -match $Pattern }
    }
    
    return $results
}

function Get-CrossLanguageRelations {
    <#
    .SYNOPSIS
        Gets relationships that span multiple languages
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$UnifiedCPG
    )
    
    return $UnifiedCPG.Relations.Values | Where-Object { $_.IsCrossLanguage() }
}

function New-UnifiedNode {
    <#
    .SYNOPSIS
        Factory function to create UnifiedNode instances
    .DESCRIPTION
        Provides a way to create UnifiedNode objects without direct class instantiation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Id,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [UnifiedNodeType]$Type,
        
        [string]$Language = "Unknown",
        
        [string]$FullyQualifiedName = "",
        
        [string]$OriginalType = "",
        
        [hashtable]$Properties = @{},
        
        [hashtable]$LanguageSpecificData = @{},
        
        [hashtable]$Position = @{}
    )
    
    $node = [UnifiedNode]::new()
    $node.Id = $Id
    $node.Name = $Name
    $node.Type = $Type
    $node.Language = $Language
    $node.FullyQualifiedName = $FullyQualifiedName
    $node.OriginalType = $OriginalType
    $node.Properties = $Properties
    $node.LanguageSpecificData = $LanguageSpecificData
    $node.Position = $Position
    
    return $node
}

# Export functions
# Export module members
# Note: Classes are automatically exported in PowerShell modules
Export-ModuleMember -Function @(
    'New-UnifiedCPG',
    'New-UnifiedNode',
    'Get-UnifiedNodes', 
    'Get-CrossLanguageRelations'
)

Write-Verbose "CrossLanguage-UnifiedModel module loaded successfully"

# SIG # Begin signature block
# Cross-Language Unified Model for Enhanced Documentation System
# Week 1, Day 4 - Unified representation across programming languages
# SIG # End signature block