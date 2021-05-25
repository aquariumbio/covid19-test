# SG
# functions for sorting operations
# 
# used in Library Cloning/Streak Plates on Media
module SortHelper
    
    #-----------------------------------------------------------------------------
    # sort ops by more than one input/output attribute, at io or item level 
    # algorithm: 
    # all possible unique values 1..n are sorted lexicographically and assigned numbers [1..n]
    # attributes add value in powers of ops.length**(k), where k is the REVERSE position of the attribute in the matrix. 
    # (most important == first.) 
    # ops.length insures that the first level is high enough 
    #-----------------------------------------------------------------------------
    def sortByMultipleIO(ops, ioStrs, ioNames, attributeStrs, itemLevels)
        
        allVals_mat=Array.new()
        ioStrs.each_with_index { |ioStr, i|
            allVals=[]
            keys=[]
            hash=Hash.new()
            caseArray=[ioStrs[i],itemLevels[i]]
            case caseArray
            when ["in","io"]
                allVals = ops.map { |op| op.input(ioNames[i]).send(attributeStrs[i]) } 
            when ["in","item"]
                allVals = ops.map { |op| op.input(ioNames[i]).item.send(attributeStrs[i]) } 
            when ["in","val"]
                allVals = ops.map { |op| op.input(ioNames[i]).val } 
            when ["in","collection"]
                allVals = ops.map { |op| op.input(ioNames[i]).collection.send(attributeStrs[i]) } 
            when ["out","io"]
                allVals = ops.map { |op| op.output(ioNames[i]).send(attributeStrs[i]) } 
            when ["out","item"]
                allVals = ops.map { |op| op.output(ioNames[i]).item.send(attributeStrs[i]) } 
            when ["out","val"]
                allVals = ops.map { |op| op.output(ioNames[i]).val } 
            when ["out","collection"]
                allVals = ops.map { |op| op.output(ioNames[i]).collection.send(attributeStrs[i]) } 
            else
                raise "Bad ioStr #{ioStr} in #{__method__.to_s}, please check!"
            end
            
            begin
                keys=allVals.uniq.sort 
            rescue
                raise "Can't sort [#{ioStrs[i]},#{itemLevels[i]}] in <b>#{__method__.to_s}</b>, please check!"
            end
            
            values=Array (0..keys.length-1)
            values.map! {|v| v=v*( (ops.length+1)**(ioStrs.length - i) ) }
            hash=Hash[keys.zip(values)]
            allVals_mat[i]=hash
        }
        
        ops.sort! { |a, b| sortVal(a, ioStrs, ioNames, attributeStrs, itemLevels, allVals_mat)  <=> sortVal(b, ioStrs, ioNames, attributeStrs, itemLevels, allVals_mat) }
        return ops
    end # def
  
    #-----------------------------------------------------------------------------
    # get op value for sort  
    #-----------------------------------------------------------------------------
    def sortVal(op, ioStrs, ioNames, attributeStrs, itemLevels, allVals_mat)
        val = 0
        allVals_mat.each_with_index { |hash, i|
            case [ioStrs[i],itemLevels[i]]
            when ["in","io"]
                val += hash[op.input(ioNames[i]).send(attributeStrs[i])]
            when ["in","item"]
                val += hash[op.input(ioNames[i]).item.send(attributeStrs[i])] 
            when ["in","val"]
                val += hash[op.input(ioNames[i]).val] 
            when ["in","collection"]
                val += hash[op.input(ioNames[i]).collection.send(attributeStrs[i])] 
            when ["out","io"]
                val += hash[op.output(ioNames[i]).send(attributeStrs[i])] 
            when ["out","item"]
                val += hash[op.output(ioNames[i]).item.send(attributeStrs[i])] 
            when ["out","val"]
                val += hash[op.output(ioNames[i]).val] 
            when ["out","collection"]
                val += hash[op.output(ioNames[i]).collection.send(attributeStrs[i])] 
            else
                raise "Bad input [#{ioStrs[i]},#{itemLevels[i]}] in <b>#{__method__.to_s}</b>, please check!"
            end
        }
        return val
    end # def
     
end # module