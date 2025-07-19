# Smart Fire Prevention System

A comprehensive blockchain-based fire prevention and safety management system built on Stacks using Clarity smart contracts.

## System Overview

The Smart Fire Prevention System consists of five interconnected smart contracts that work together to provide a complete fire safety management solution:

### 1. Risk Assessment Contract (`risk-assessment.clar`)
- Evaluates fire hazard levels in buildings and areas
- Calculates risk scores based on multiple factors
- Maintains risk assessment history
- Provides risk level classifications

### 2. Inspection Scheduling Contract (`inspection-scheduling.clar`)
- Coordinates safety checks and code compliance inspections
- Manages inspection schedules and assignments
- Tracks inspection completion status
- Handles inspector assignments and availability

### 3. Equipment Maintenance Contract (`equipment-maintenance.clar`)
- Ensures fire suppression systems functionality
- Tracks maintenance schedules and completion
- Manages equipment status and service records
- Handles maintenance technician assignments

### 4. Emergency Response Contract (`emergency-response.clar`)
- Coordinates firefighter dispatch and resource allocation
- Manages emergency incident reporting
- Tracks response times and resource deployment
- Handles emergency contact management

### 5. Public Education Contract (`public-education.clar`)
- Manages fire safety awareness and training programs
- Tracks participant enrollment and completion
- Maintains educational content and resources
- Handles certification and compliance tracking

## Key Features

- **Decentralized Management**: All fire safety data stored on blockchain
- **Transparent Operations**: Public visibility of safety records and compliance
- **Automated Scheduling**: Smart contract-based scheduling and notifications
- **Risk-Based Prioritization**: Data-driven risk assessment and resource allocation
- **Compliance Tracking**: Automated compliance monitoring and reporting
- **Emergency Coordination**: Real-time emergency response coordination

## Technical Architecture

### Data Types
- **Risk Levels**: u1 (Low), u2 (Medium), u3 (High), u4 (Critical)
- **Status Types**: u1 (Pending), u2 (In Progress), u3 (Completed), u4 (Overdue)
- **Equipment Types**: u1 (Sprinkler), u2 (Alarm), u3 (Extinguisher), u4 (Hydrant)
- **Emergency Types**: u1 (Fire), u2 (Hazmat), u3 (Rescue), u4 (Medical)

### Access Control
- Contract owners can manage system settings
- Authorized inspectors can update inspection records
- Maintenance technicians can update equipment status
- Emergency responders can create and update incidents
- Public can access educational resources and enroll in programs

## Installation and Setup

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite
5. Deploy contracts using `clarinet deploy`

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing
- Performance and gas optimization tests

## Usage Examples

### Risk Assessment
\`\`\`clarity
;; Assess building risk
(contract-call? .risk-assessment assess-building-risk
"Building-001"
u2 ;; construction-type
u1950 ;; year-built
u5 ;; floors
u100) ;; occupancy
\`\`\`

### Schedule Inspection
\`\`\`clarity
;; Schedule safety inspection
(contract-call? .inspection-scheduling schedule-inspection
"Building-001"
u1 ;; inspection-type
u1640995200) ;; scheduled-date
\`\`\`

### Report Emergency
\`\`\`clarity
;; Report fire emergency
(contract-call? .emergency-response report-emergency
"Location-001"
u1 ;; emergency-type (fire)
u3) ;; severity
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
