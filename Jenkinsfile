#!/usr/bin/env groovy
// Copyright (c) 2018 Intel Corporation
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

// To use a test branch (i.e. PR) until it lands to master
// I.e. for testing library changes
//@Library(value="pipeline-lib@your_branch") _

def sanitized_JOB_NAME = JOB_NAME.toLowerCase().replaceAll(
                                               '/', '-').replaceAll('%2f', '-')

/* commit_pragma_cache = [:]
def cachedCommitPragma(Map config) {

    if (commit_pragma_cache[config['pragma']]) {
        return commit_pragma_cache[config['pragma']]
    }

    commit_pragma_cache[config['pragma']] = commitPragma(config)

    return commit_pragma_cache[config['pragma']]

}

def skip_stage(String stage, boolean def_val = false) {
    String value = 'false'
    if (def_val) {
        value = 'true'
    }
    return cachedCommitPragma(pragma: 'Skip-' + stage,
                              def_val: value) == 'true'
} */

def dockerfile_name() {
  if (env.TARGET == 'el-7')
      return 'Dockerfile.centos.7'
  if (env.TARGET == 'el-8')
      return 'Dockerfile.centos.8'
  if (env.TARGET == 'fedora-32')
      return 'Dockerfile.fedora.32'
  if (env.TARGET == 'fedora')
      return 'Dockerfile.fedora'
  if (env.TARGET == 'opensuse-15')
      return 'Dockerfile.leap.15'
  if (env.TARGET == 'opensuse-42')
      return 'Dockerfile.leap.42.3'
  if (env.TARGET == 'ubuntu-14.04')
      return 'Dockerfile.ubuntu.14.04'
  if (env.TARGET == 'ubuntu-16.04')
      return 'Dockerfile.ubuntu.16.04'
  if (env.TARGET == 'ubuntu-18.04')
      return 'Dockerfile.ubuntu.18.04'
  if (env.TARGET == 'ubuntu-20.04')
      return 'Dockerfile.ubuntu.20.04'
  error "Unknown target ${env.TARGET}"
}

def docker_http_proxy() {
  def proxy = ""
  if (env.HTTP_PROXY) {
    proxy += ' --build-arg HTTP_PROXY="' + env.HTTP_PROXY + '"' +
             ' --build-arg http_PROXY="' + env.HTTP_PROXY + '"'
  }
  if (env.HTTPS_PROXY) {
    proxy += ' --build-arg HTTPS_PROXY="' + env.HTTPS_PROXY + '"' +
             ' --build-arg https_PROXY="' + env.HTTPS_PROXY + '"'
  }
  return proxy
}

pipeline {
    agent { label 'lightweight' }

    environment {
        UID=sh(script: "id -u", returnStdout: true)
        BUILDARGS = "--build-arg UID=${env.UID} ${docker_http_proxy()}"
    }

    options {
        checkoutToSubdirectory('repo')
        ansiColor('xterm')
    }

    stages {
    stage('Cancel Previous Builds') {
      when { changeRequest() }
      steps {
        cancelPreviousBuilds()
      } // steps
    } // stage('Cancel Previous Builds')

    stage('Pre-Build') {
      // parallel {
      // stage('checkpatch') {
      /*  when {
          beforeAgent true
          allOf {
            expression { ! skip_stage('checkpatch') }
          } // allOf
        } // when */
        agent {
          dockerfile {
            filename 'Dockerfile.fedora'
            dir 'repo'
            label 'docker_runner'
            additionalBuildArgs '$BUILDARGS' +
                                "-t ${sanitized_JOB_NAME}-fedora "
          } // dockerfile
        } // agent
        steps {
          checkoutScm url: 'https://github.com/daos-stack/code_review.git',
                      checkoutDir: 'code_review',
                      branch: 'master'
          sh label: 'Linting',
             script: 'repo/checkpatch_lint.sh'
        } //steps
        post {
          always {
            archiveArtifacts artifacts: 'pylint.log',
                             allowEmptyArchive: true
          } // always
        } // post
      // } // stage('checkpatch')
      // } parallel
    } // stage('Pre-Build')
    stage('Build') {
    matrix {
      agent { label 'lightweight' }
      axes {
        axis {
          name 'TARGET'
          values 'el-7', 'el-8', 'fedora-32', 'fedora',
                 'opensuse-15',
                 'ubuntu-16.04', 'ubuntu-18.04', 'ubuntu-20.04'
        }
      }
      stages{
      stage('Python') {
        agent {
          dockerfile {
            filename dockerfile_name()
            dir 'repo'
            label 'docker_runner'
            additionalBuildArgs '$BUILDARGS'
          }
        }
        steps {
            // Have to map /opt/dco/python to a workspace directory
            sh script: '''export DISTRO=${TARGET}
                          repo/build_opt_do_python.sh'''
        }
        post {
          success {
            archiveArtifacts artifacts: "artifacts/${env.TARGET}/**"
          }
        } // post
      } // stage('Python')
      } // stages
    } // matrix
    } // stage('Build')
    } // stages
}
