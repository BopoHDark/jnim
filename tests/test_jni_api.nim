import private.jni_api,
       threadpool,
       unittest,
       strutils

suite "jni_api":
  test "API - Initialization":
    proc thrNotInited {.gcsafe.} = 
      test "API - Thread initialization (VM not initialized)":
        check: not isJNIThreadInitialized()
        expect JNIException:
          initJNIThread()
        deinitJNIThread()
    spawn thrNotInited()
    sync()

    initJNI(JNIVersion.v1_6, @["-Djava.class.path=build"])
    expect JNIException:
      initJNI(JNIVersion.v1_6, @[])
    check: isJNIThreadInitialized()

    proc thrInited {.gcsafe.} = 
      test "API - Thread initialization (VM initialized)":
        check: not isJNIThreadInitialized()
        initJNIThread()
        check: isJNIThreadInitialized()
        deinitJNIThread()
    spawn thrInited()
    sync()

  test "API - JVMClass":
    # Find existing class
    discard JVMClass.getByFqcn(fqcn"java.lang.Object")
    discard JVMClass.getByName("java.lang.Object")
    # Find non existing class
    expect Exception:
      discard JVMClass.getByFqcn(fqcn"java.lang.ObjectThatNotExists")
    expect Exception:
      discard JVMClass.getByName("java.lang.ObjectThatNotExists")

  test "API - call System.out.println":
    let cls = JVMClass.getByName("java.lang.System")
    let outId = cls.getStaticFieldId("out", fqcn"java.io.PrintStream")
    let `out` = cls.getObject(outId)
    let outCls = `out`.getClass
    let printlnId = outCls.getMethodId("println", "($#)V" % string.jniSig)
    `out`.callVoidMethod(printlnId, ["Hello, world".newJVMObject.toJValue])

  test "API - TestClass - static fields":
    let cls = JVMClass.getByName("TestClass")

    check: cls.getObject("objectField").toStringRaw == "obj"
    check: cls.getChar("charField") == 'A'.jchar
    check: cls.getByte("byteField") == 1
    check: cls.getShort("shortField") == 2
    check: cls.getInt("intField") == 3
    check: cls.getLong("longField") == 4
    check: cls.getFloat("floatField") == 1.0
    check: cls.getDouble("doubleField") == 2.0
    check: cls.getBoolean("booleanField") == JVM_TRUE

    cls.setObject("objectField", "Nim".newJVMObject)
    cls.setChar("charField", 'B'.jchar)
    cls.setByte("byteField", 100)
    cls.setShort("shortField", 200)
    cls.setInt("intField", 300)
    cls.setLong("longField", 400)
    cls.setFloat("floatField", 500.0)
    cls.setDouble("doubleField", 600.0)
    cls.setBoolean("booleanField", JVM_FALSE)
    
    check: cls.getObject("objectField").toStringRaw == "Nim"
    check: cls.getChar("charField") == 'B'.jchar
    check: cls.getByte("byteField") == 100
    check: cls.getShort("shortField") == 200
    check: cls.getInt("intField") == 300
    check: cls.getLong("longField") == 400
    check: cls.getFloat("floatField") == 500.0
    check: cls.getDouble("doubleField") == 600.0
    check: cls.getBoolean("booleanField") == JVM_FALSE
