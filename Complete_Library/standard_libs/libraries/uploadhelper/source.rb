# written by SG
# helper function for uploading files
# note: data associations should be handled externally
module UploadHelper
    
    require 'csv'
    require 'open-uri'
    
    #------------------------------------------
    # upload files 
    #
    # inputs:
    # dirname - directory where files are located, or full path including filename
    # expUploadNum - expected number of files to upload
    # tries - max. number of attempts to upload expectedNum files 
    #
    # returns: array of Upload items 
    #
    # EXAMPLES of how to associate correctly:     
    # data associations - 1st gel image        
    # up_bef=ups[0]
    # op.plan.associate "gel_image_bef", "combined gel fragment", up_bef  # upload association, link 
    # op.input(INPUT).item.associate "gel_image_bef", up_bef              # regular association
    # op.output(OUTPUT).item.associate "gel_image_bef", up_bef            # regular association 
    #------------------------------------------
    def uploadData(dirname, expUploadNum, tries)

        uploads={}      # holds result of upload block   
        numUploads=0    # number of uploads in current attempt
        attempt=0       # number of upload attempts
            
        # get uploads
        loop do
            #if(numUploads==expUploadNum)  
            #    show {note "Upload complete."}
            #end
            break if ( (attempt>=tries) || (numUploads==expUploadNum) ) # stopping condition
            attempt=attempt+1;
            uploads = show do
                title "Select <b>#{expUploadNum}</b> file(s)"
                note "File(s) location is: #{dirname}"
                if(attempt>1)
                    warning "Number of uploaded files (#{numUploads}) was incorrect, please try again! (Attempt #{attempt} of #{tries})"
                end
                upload var: "files"
            end
            # number of uploads    
            if(!uploads[:files].nil?)
                numUploads=uploads[:files].length
            end
        end
        
        if(numUploads!=expUploadNum)
            show {note "Final number of uploads (#{numUploads}) not equal to expected number #{expUploadNum}! Please check."}
            return nil
        end
        
        # format uploads before returning 
        ups=Array.new # array of upload hashes
        if (!uploads[:files].nil?)
            uploads[:files].each_with_index do |upload_hash, ii|
                up=Upload.find(upload_hash[:id]) 
                ups[ii]=up
            end
        end
        
        # return
        ups
        
    end # def
    
    
    # Opens .csv file upload item using its url and stores it line by line in a matrix
    #
    # @param upload [upload_obj] the file that you wish to read from
    # @return matrix [2D-Array] is the array of arrays of the rows read from file, if csv
    def read_url(upload)
        url = upload.url
        matrix = []
        CSV.new(open(url)).each {|line| matrix.push(line)}
        # open(url).each {|line| matrix.push(line.split(',')}
        return matrix
    end
     
end # module

   