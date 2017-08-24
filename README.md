## Docker Image for Overture in a Desktop Environment

This Docker image is for learning and trying Overture for solving numerical PDEs.

[![Build Status](https://travis-ci.org/unifem/overture-desktop.svg?branch=master)](https://travis-ci.org/unifem/overture-desktop)  [![Docker Image](https://images.microbadger.com/badges/image/unifem/overture-desktop.svg)](https://microbadger.com/images/unifem/overture-desktop)

### About [Overture](http://overtureframework.org/)

Overture is an object-oriented code framework for solving partial differential equations (PDEs). It provides a portable, flexible software development environment for applications that involve the simulation of physical processes in complex moving geometry . It is implemented as a collection of C++ libraries that enable the use of finite difference and finite volume methods at a level that hides the details of the associated data structures. Overture is designed for solving problems on a structured grid or a collection of structured grids. In particular, it can use curvilinear grids, adaptive mesh refinement, and the composite overlapping grid method to represent problems involving complex domains with moving components. Its grid generator, Ogen, can be used to generate overset grids.

The CG (Composite Grid) Suite of PDE solvers are built on top of Overture and can be used to solve a wide class of problems in contiuum mechanics. These solvers include Cgins (incompressible flow), Cgcns (compressible flow), Cgsm (solid mechanics), Cgad (advection diffusion), Cgmx (eletromagnetics) and Cgmp (multi-physics and fluid-structure interations).
