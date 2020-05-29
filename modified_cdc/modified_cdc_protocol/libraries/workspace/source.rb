# Library for handling the cleaning and preparing of workspaces.
#
# @author Justin Vrana <jvrana@uw.edu>


class Workspace
    
    # initialize the workspace
    def initialize(args)
        @protocol = args[:protocol]
        @locations = []
    end
    
    # get the current location of the technician
    def current_location()
        @locations.last 
    end
    
    def change_gloves()
        @protocol.note "Change gloves"
    end
    
    # prepare the workspace according to the options
    def prepare()
        @protocol.show do
            title "Prepare the workspace"
        end
    end
    
    # move the technician to a new location
    def move(args)
        @protocol.show do
            title "Move to #{args[:to]}"
        end
        @locations.append(args[:to])
    end
    
    # cleanup the workspace(s)
    def cleanup()
        @protocol.show do
            title "Cleanup the workspace"
        end
    end
    
    def clean_hood()
        # clean the hood
        @protocol.show do
            title "Clean the hood"
            note "Clean the space with bleach and ethanol in case there is any spilling"
            note "Change gloves (now your gloves may be contaminated with some samples)"
        end
    end
end

class WorkspaceLocation
    attr_reader :name
    
    def initialize(args)
        @name = args[:name] 
    end
end