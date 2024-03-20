--[[ Info
Module is for Connecting and disconnecting from the Partitioned events
The Network Partitioning will be following ////Octree/// NOT Hexadeca//////// 
A Partition here will be 500x500 
The Partition Event will have a Varadic function attached to it the FunctionName and its args will be recieved through here
Have a dictionary of the functions in a submodule
]]

--[[ Modules needed
Event_Manager
Map_Manager
]]
--[[
    From Client {
        the Current partitionNumnber, PartitionCentrePos  of the Client 
        Connect to the Partition Event and disconnect 
        From Map_Manager {
            Disconnect from unrendered Partitions
        }
    }
]]