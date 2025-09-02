---
Function Name: Get-SystemHealth

SYNOPSIS
--------
Returns the health status of a system based on its connectivity and running services.

SYNTAX
------
Get-SystemHealth [-ComputerName] <string> [[-TimeoutSeconds] <int>] [[-IncludeDetails] <switch>] [<CommonParameters>]

DESCRIPTION
-----------
The Get-SystemHealth function uses the Test-Connection cmdlet to check if a system is reachable, and then retrieves the running services on that system using the Get-Service cmdlet. The function returns an object with the following properties:

* Status: Indicates whether the system is healthy or not (either "Healthy" or "Unreachable").
* ServicesRunning: If the system is reachable, this property contains the number of running services on that system.
* Timestamp: The date and time when the function was executed.

PARAMETERS
----------
ComputerName (mandatory): Specifies the name or IP address of the computer to check.
TimeoutSeconds (optional): Specifies the timeout in seconds for the ping test. Default value is 30 seconds.
IncludeDetails (optional): If set, additional details about the system's health are included in the output object.

EXAMPLES
--------
Example 1: Get the health status of a remote computer
----------------------------------------------------
PS C:\> Get-SystemHealth -ComputerName "remote-server"

Status                                                                                    ServicesRunning Timestamp
------                                                                                    --------------- ---------
Healthy                                                                                          20 1/23/2022 1:25:34 PM

Example 2: Get the health status of a remote computer with detailed output
--------------------------------------------------------------------------
PS C:\> Get-SystemHealth -ComputerName "remote-server" -IncludeDetails

Status                                                                                    ServicesRunning Timestamp
------                                                                                    --------------- ---------
Healthy                                                                                          20 1/23/2022 1:25:34 PM

RETURN VALUES
-------------
The function returns an object with the following properties:

* Status: Indicates whether the system is healthy or not (either "Healthy" or "Unreachable").
* ServicesRunning: If the system is reachable, this property contains the number of running services on that system.
* Timestamp: The date and time when the function was executed.

ERROR HANDLING
-------------
If an error occurs during execution, the function returns an object with the following properties:

* Status: Indicates whether the system is healthy or not (either "Healthy" or "Unreachable").
* Message: A description of the error that occurred.

NOTES
-----
The Get-SystemHealth function uses the Test-Connection cmdlet to check if a system is reachable, and then retrieves the running services on that system using the Get-Service cmdlet. The function returns an object with the following properties:

* Status: Indicates whether the system is healthy or not (either "Healthy" or "Unreachable").
* ServicesRunning: If the system is reachable, this property contains the number of running services on that system.
* Timestamp: The date and time when the function was executed.
