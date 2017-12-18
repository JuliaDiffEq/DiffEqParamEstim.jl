export DiffEqObjective, build_loss_objective

struct DiffEqObjective{F,F2} <: Function
  cost_function::F
  cost_function2::F2
end

(f::DiffEqObjective)(x) = f.cost_function(x)
(f::DiffEqObjective)(x,y) = f.cost_function2(x,y)

function build_loss_objective(prob::DEProblem,alg,loss,regularization=nothing;mpg_autodiff = false,
                              verbose_opt = false,verbose_steps = 100,
                              prob_generator = problem_new_parameters,
                              autodiff_prototype = mpg_autodiff ? zeros(num_params(prob)) : nothing,
                              autodiff_chunk = mpg_autodiff ? ForwardDiff.Chunk(autodiff_prototype) : nothing,
                              kwargs...)
  if verbose_opt
    count = 0 # keep track of # function evaluations
  end
  cost_function = function (p)
    tmp_prob = prob_generator(prob,p)
    if typeof(loss) <: Union{CostVData,L2Loss,LogLikelihood}
      sol = solve(tmp_prob,alg;saveat=loss.t,save_everystep=false,dense=false,kwargs...)
    else
      sol = solve(tmp_prob,alg;kwargs...)
    end

    if regularization == nothing
      loss_val = loss(sol)
    else
      loss_val = loss(sol) + regularization(p)
    end
    if verbose_opt
      count::Int += 1
      if mod(count,verbose_steps) == 0
        println("Iteration: $count")
        println("Current Cost: $loss_val")
        println("Parameters: $p")
      end
    end
    loss_val
  end

  if mpg_autodiff
    gcfg = ForwardDiff.GradientConfig(cost_function, autodiff_prototype, autodiff_chunk)
    g! = (x, out) -> ForwardDiff.gradient!(out, cost_function, x, gcfg)
  else
    g! = (x, out) -> Calculus.finite_difference!(cost_function,x,out,:central)
  end
  cost_function2 = function (p,grad)
    if length(grad)>0
      g!(p,grad)
    end
    cost_function(p)
  end
  DiffEqObjective(cost_function,cost_function2)
end
