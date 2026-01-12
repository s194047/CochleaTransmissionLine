# Program structure
Several modules

## Model
This module contains:
* `function cochlea_transmission_line!(...)`
* All structs necessary for building `CochleaModelParams`
    * make function for `CochleaModelParams` should also take stimulus function.
    * Entire hierarchy
* `d_impl` and `c_impl` (find better names)

## Params
Your concrete values for the model and the stimulus function. You could have several such modules *or* several sets of values here.

It should import `Model` and then define and export:
* An instance of `CochleaTransmissionLineConstants`
* The stimulus function definition

## Main
This ties it all together
* Import the above modules
* Make an instance of `CochleaModelParams` from the values in the `Params` module
* Run the solver
* Save the result

You could refactor some of this into a solver module that does the hard work. Example what a `Solver` module could do:
* Export one `solve` function that takes as parameters:
  * `CochleaModelParams` (everything that the solver callback function needs)
  * Initial conditions
  * Time span of simulation (2 secs)
  * Slot size (100 ms between save)
  * Output dir for data

Then call this from `Main`, so main simply construct the input values and call the `Solver` module.
