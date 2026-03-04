#!/usr/bin/env bash

sleep 15000
kill -- -$(ps | grep "batch-run_yes-no-up-down.sh" | grep -v grep | cut -d" " -f1)
