# CliMA Variable List

This document unifies the naming conventions used across the CliMA codebase. It defines 'reserved' variable names in `<property>_<species>` format with the default working fluid (no-subscript) being moist air.

## Type parameters

The Julia code typically uses `T` as a type parameter, however this conflicts with the typical usage for temperature. Instead, good choices are:
- `FT` for floating point values

## Names reserved for debug variables
- `dummy`
- `scratch`

## Working Fluid and Equation of State
- `q_dry` = dry air mass fraction
- `q_vap` = specific humidity, vapor
- `q_liq` = specific humidity, liquid
- `q_ice` = specific humidity, ice
- `q_con` = specific humidity, condensate
- `q_tot` = specific humidity, total

- `P_<species>` = pressure, species (no subscript == default working fluid moist air)
- `ρ_<species>` = density, species (no subscript == default working fluid moist air)
- `R_m` = gas constant, moist
- `R_d` = gas constant, dry
- `R_v` = gas constant, water vapor
- `T` = temperature, moist air
- `T_<species>` = temperature, species

## Mass Balance
- `dt` = time increment
- `u` = x-velocity
- `v` = y-velocity
- `w` = z-velocity

## Moisture balances
- `source_qt` = local source/sink of water mass
- `diffusiveflux_vap` = diffusive flux, water vapor
- `diffusiveflux_liq` = diffusive flux, cloud liquid
- `diffusiveflux_ice` = diffusive flux, cloud ice
- `diffusiveflux_tot` = diffusive flux, total

## Momentum balances
- `U` = x-momentum
- `V` = y-momentum
- `W` = z-momentum (2D/3D: this is the vertical coordinate)
- `Ω_x` = x-angular momentum
- `Ω_y` = y-angular momentum
- `Ω_z` = z-angular momentum
- `τ_xx` = stress tensor ((1,1) component)
- `τ_<ij>` = replace ij with combination of x/y/z to recover appropriate value
- `λ_stokes` = Stokes parameter

## Energy balance
*Lower case `e_<type>` suggests specific (per unit mass) quantities*
- `e_kin_<spe>` = specific energy per unit volume, kinetic
- `e_pot_<spe>` = specific energy per unit volume, potential
- `e_int_<spe>` = specific energy per unit volume, internal
- `e_tot_<spe>` = specific energy per unit volume, total

- `E_kin_<spe>` = energy, kinetic
- `E_pot_<spe>` = energy, potential
- `E_int_<spe>` = energy, internal
- `E_tot_<spe>` = energy, total

- `cv_m`, `cv_d`, `cv_l`, `cv_v`, `cv_i` = isochoric specific heat (moist, dry, liquid, vapor, ice)
- `cp_m`, `cp_d`, `cp_l`, `cp_v`, `cp_i` = isobaric specific heat (moist, dry, liquid, vapor, ice)

## Microphysics
- `q_rai` = specific humidity, rain [kg/kg]
- `terminal_velocity` = mass weighted average rain fall speed [m/s]
- `conv_q_vap_to_q_liq` = tendency to q_liq and q_ice due to condensation/evaporation
- `conv_q_liq_to_q_rai_acnv` = tendency to q_rai due to autoconversion
- `conv_q_liq_to_q_rai_accr` = tendency to q_rai due to accretion
- `conv_q_rai_to_q_vap` = tendency to q_vap due to evaporation

## Self-correction

If this guide is discovered to be stale or missing a pattern, update it.
