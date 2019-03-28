# MIT License
# 
# Copyright (c) 2019 Qlik Support
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE`
# SOFTWARE.

# FQDN to Qlik Sense central node
$FQDN = "qlikserver.domain.local"

# User credentials to use for authetication
$UserName   = "Administrator"
$UserDomain = "Domain"

# Exact name of task to trigger 
$Taskname = "Reload task of My App"

# 16 character Xrefkey to use for QRS API call
$XrfKey="hfFOdh87fD98f7sf"

# HTTP headers to be used in REST API call
$HttpHeaders = @{}
$HttpHeaders.Add("X-Qlik-Xrfkey","$XrfKey")
$HttpHeaders.Add("X-Qlik-User", "UserDirectory=$UserDomain;UserId=$UserName")
$HttpHeaders.Add("Content-Type", "application/json")

$HttpBody = @{}

$ClientCert = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where {$_.Subject -like '*QlikClient*'}
#$ClientCert

$TaskReload = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/task/start/synchronous?xrfkey=$($xrfkey)&name=$($Taskname)" `
                                -Method POST `
                                -Headers $HttpHeaders  `
                                -Body $HttpBody `
                                -ContentType 'application/json' `
                                -Certificate $ClientCert

# Print result
$TaskReload