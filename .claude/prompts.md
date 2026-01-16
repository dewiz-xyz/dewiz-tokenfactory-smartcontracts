# Custom Prompts for Dewiz Token Factory

This file contains reusable prompts for common tasks in this project.

## Security Analysis
```
Run a comprehensive security analysis on the smart contracts:
1. Run Slither with --exclude-dependencies
2. Check for common vulnerabilities (reentrancy, access control, etc.)
3. Verify all external calls follow checks-effects-interactions
4. Review gas optimization opportunities
5. Provide a summary report
```

## Add New Token Feature
```
Add a new feature to all token types (ERC20, ERC721, ERC1155):
1. Implement the feature in all three token contracts
2. Update the factory interfaces if needed
3. Add comprehensive tests for each token type
4. Update NatSpec documentation
5. Run all tests to ensure nothing breaks
6. Run Slither to check for new issues
```

## Create Compliance Hook
```
Create a new compliance hook implementation:
1. Review IComplianceHook interface
2. Implement the hook with specific validation logic
3. Add comprehensive tests
4. Document gas implications
5. Provide example usage
```

## Deploy Checklist
```
Pre-deployment checklist:
1. All tests passing
2. Slither analysis clean
3. Gas optimization review
4. Documentation complete
5. Access control verified
6. Constructor parameters validated
7. Deployment script tested
```

## Test Coverage
```
Generate and analyze test coverage:
1. Run forge coverage
2. Identify uncovered lines
3. Add tests for uncovered code paths
4. Verify edge cases are tested
5. Report final coverage percentage
```
