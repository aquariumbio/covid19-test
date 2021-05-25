def cost(op)
  trans = op.get(:transactions) || [{ amount: 0.1 }]
  total_cost = trans.map { |t| t[:amount] }.sum
  
  { labor: 0, materials: total_cost }
end