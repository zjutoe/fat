#!/bin/bash

valgrind --tool=lackey --trace-mem=yes --trace-superblocks=yes $@

