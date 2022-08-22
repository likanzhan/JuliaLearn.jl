"""
    CheckOrthogonality(mat::AbstractMatrix)

Check whether the contrast matrix is orthogonal or not.

"""
function CheckOrthogonality(mat::AbstractMatrix)
    # 原则一：每一行中，加权数的和必须为 0；
    rule1 = all(isapprox.(sum(mat, dims = 2), 0; atol = 1e-5))
  
    # 原则二：每一列中，所有两两成对加权数乘积的总和必须为 0；
    rule2 = 0
    for col in eachcol(mat), 
        (find, fval) in enumerate(col), 
        (sind, sval) in enumerate(col)
      (find == sind) || (rule2 += fval * sval)
    end
    rule2 = isapprox.(rule2, 0; atol = 1e-5)
  
    # 结果：汇总两个原则
    return all([rule1, rule2])
end
  