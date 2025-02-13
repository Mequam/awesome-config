#!/bin/bash

echo $@ | tr ',' '\n' | fzf > /tmp/topic
