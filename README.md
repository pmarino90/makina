# Makina
A simple application manager for self-hosted environments

**UNDER ACTIVE DEVELOPMENT, DO NOT USE FOR ANYTHING IMPORTANT**

## Description
Makina is a simple hosting platform for self hosted environment, you pick a server, install Makina and you're ready to host different services there.
It is designed to be simple and generally understandable, doesn't require extensive configuration. 

Services are private by default but can be exposed using Traefik, which Makina supports out of the box, with HTTPS enabled by default. Clicking a checbox
in a given service's configuration exposes the service with now more added work (except DNS configuration if needed).

Services are grouped in stacks and every service within a stack can reach the other, however services in other stacks are isolated.

Although Makina aims to be able to support multiple stacks it is not designed to support multi-tenancy, each logged-in user can access and perform the same operations.

## Current Status
At the moment Makina can run on a system with Docker installed and lets you host services of all kinds. To consider this a good 1.0 version the following are missing:
- [ ] Possibility to reference secrets between different services within the same stack
- [ ] Possibility to reference services in others wihin the same stack
- [ ] Simple coverter from `docker-compose.yml` to fully functioning stack
- [ ] Simple installer to support the user in their first setup

## Contribution 
At the moment I am not accepting direct code contributions. 
Being able to keep up with those is rather time consuming and I am not focusing on this full time. 
However suggestions, bug reports and so on a more than welcome.
