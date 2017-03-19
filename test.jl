using DiffEqParamEstim, OrdinaryDiffEq, ParameterizedFunctions,
      DiffEqBase, RecursiveArrayTools
using Base.Test

# Here's the problem to solve

f = @ode_def_nohes LotkaVolterraTest begin
  dx = a*x - b*x*y
  dy = -c*y + d*x*y
end a=>1.5 b=1.0 c=3.0 d=1.0

u0 = [1.0;1.0]
tspan = (0.0,10.0)
prob = ODEProblem(f,u0,tspan)
sol = solve(prob,Tsit5())

# Generate random data based off of the known solution

t = collect(linspace(0,10,200))
randomized = [(sol(t[i]) + .01randn(2)) for i in 1:length(t)]
data = vecvec_to_mat(randomized)

fit = lm2s_fit(prob,t,vec(data),[1.0],Tsit5(),1.5,show_trace=true,lambda=10000.0)
param = fit.param
