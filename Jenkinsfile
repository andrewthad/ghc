pipeline {
  agent any
  parameters {
    booleanParam(name: 'build_docs', defaultValue: false, description: 'build and upload documentation')
  }

  stages {
    stage('Build') {
      steps {
        sh 'git submodule update --init --recursive'
        sh '''
           ./boot
           ./configure --enable-tarballs-autodownload
           make -j$THREADS
           make THREADS=$THREADS test
           '''
      }
    }
  }
}
