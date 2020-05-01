# Apex Propellant

An _Elegant Object_ oriented alternative solution to Apex trigger handling. It's not rocket science, I promise.

```
       ^
      / \
     /___\
    |=   =|
    |  _  |
    | (_) |
    |     |
    |  _  |
   /| (_) |\   
  / |     | \  
 /  |##!##|  \ 
|  /|##!##|\  |
| / |##!##| \ |
|/   ^ | ^   \|
     ( | )
    ((   ))
   (( pro ))
   (( pel ))
   (( lan ))
    (( t ))
     (( ))
      ( )
       .
       .
```
**Deploy to SFDX Scratch Org:**
[![Deploy to SFDX](https://deploy-to-sfdx.com/dist/assets/images/DeployToSFDX.svg)](https://deploy-to-sfdx.com)

**Deploy to Salesforce Org:**
[![Deploy to Salesforce](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/?owner=berardo&repo=apex-propellant&ref=master)


## Overview

It's well known that triggers should be logicless, which means we should avoid coding directly within them. Instead, it's advisable to make calls to business classes not rarely called trigger handlers.

However, what's commonly overlooked is the dependency from the handler back to the Apex `Trigger` object.

The Apex Propellant library is inspired by a popular solution called [`TriggerHandler`](https://github.com/kevinohara80/sfdc-trigger-framework), a common generic class that can be extended to override methods like `beforeInsert()` or `afterUpdate()`, so that these methods are executed when triggers call something like:

```java
new MyBeautifulClassThatExtendsTriggerHandler().run();
```

However, while I agree this is an easy way to shift complex logics away from triggers, it doesn't bring much benefit as the handler still needs to deal with `Trigger.new`, `Trigger.old` and so on. This unwated dependency makes handler as not unit testable as triggers themselves.

On the other hand, **Apex Propellant** is a simple alternative targeting the same goal but also:

- Decoupling handlers from triggers and `System.Trigger`, allowing them to be tested in isolation
- Promoting an easy, truly object oriented API
- Promoting the usage of [immutable objects](https://en.wikipedia.org/wiki/Immutable_object)
- Giving you control over handler call repetitions and bypasses

## How it works

The intention is to make the analogy speak for itself.
You have a trigger and you aim to get your rocket code flying around the space every time your trigger is ... triggered.

That being said, as a real-world rocket, when your code takes off, it should not care about anything that was left off the ground. All the data that you need to decide what to do and where to go should be there with you.

### Show me the code!

First things first, create a trigger and build your rocket:

```java
trigger AccountTrigger on Account(before insert) {
  OnBeforeRocket rocket = new MyAmazingRocket();
}
```

In order to reach the stars, you also need a Propellant, which is a gas, fuel or artifact to reach what's called the [_Escape Velocity_](https://en.wikipedia.org/wiki/Escape_velocity). Therefore, your very next step is to build a `Propellant` object then fire it.

```java
trigger AccountTrigger on Account(before insert) {
  OnBeforeRocket rocket = new MyAmazingRocket(); // 5, 4, 3, 2, 1 ...
  new Propellant(rocket).fireOff(); // Can you hear the sound? 🚀
}
```

### How should my rocket look like?

The bare minimum code you write to make the trigger above throw your rocket up in the space is like below:

```java
public class MyAmazingRocket extends OnInsertRocket {
  public void flyOnBefore() {
    System.debug('Yay, my 🚀 has gone through the ⛅️ on its way to the ✨');
  }
  public void flyOnAfter() {}
}
```

The `OnInsertRocket` is an abstract class that implements the two important interfaces `OnBeforeRocket` and `OnAfterRocket` but leave it alone for now.

The `flyOnBefore()` method is the only one called here because your trigger is `before insert` only. Propellant knows that and handles that for you, don't worry.

But why am I declaring `flyOnAfter()` if I don't need it?

Hey, you're smart! ... and you're right!

Alternatively you could do it:

```java
public class MyAmazingRocket implements OnBeforeRocket {
  public void flyOnBefore() {
    System.debug('Yay, my 🚀 has gone through the ⛅️ on its way to the ✨');
  }
  public Boolean canTakeOff(TriggerOperation fireWhen, Propellant propellant) {
    return true;
  }
}
```
Like I said before, even though the previous example introduced an abstract class, you ended up writing slightly less than now.

In order to fly on `before insert` trigger, your rocket only needs to implement `OnBeforeRocket`, which requires you to implement your proper flight (`flyOnBefore`) and another method that I'm gonna explain on the next section. Bear with me!

You might be asking (btw, you ask a lot, I like that 😍!), what about `after insert`?

Easy:
```java
public class MyAmazingRocket implements OnAfterRocket {
  public void flyOnAfter() {
    System.debug('Yay, my 🚀 is reaching the 🌚');
  }
  public Boolean canTakeOff(TriggerOperation fireWhen, Propellant propellant) {
    return true;
  }
}
```

I know, I know ... you can have both:
```java
public class MyAmazingRocket implements OnAfterRocket {
  public void flyOnBefore() {
    System.debug('Yay, my 🚀 has gone through the ⛅️ on its way to the ✨');
  }
  public void flyOnAfter() {
    System.debug('Yay, my 🚀 is reaching the 🌚');
  }
  public Boolean canTakeOff(TriggerOperation fireWhen, Propellant propellant) {
    return true;
  }
}
```
There's only one little thing to change when your rocket wants to take off twice in a single transaction (on before and on after triggers), you need to let `Propellant` know. Again, it's so easy:

```java
trigger AccountTrigger on Account(before insert) {
  OnBeforeRocket rocket = new MyAmazingRocket(); // 5, 4, 3, 2, 1 ...
  new Propellant(rocket, rocket).fireOff(); // Can you hear the sound? 🚀
}
```
If you didn't spot the difference, now we passed the same rocket instance twice.

I think you got the point. So let's move on to the Rocket hierarchy and finally expain the little `canTakeOff` kid.

### The Rocket hierarchy

There's one generic interface called `Rocket` that exposes what every rocket needs to do. Fortunatelly it's just one single method:
```java
public interface Rocket {
  Boolean canTakeOff(TriggerOperation fireWhen, Propellant propellant);
}

```
`canTakeOff` gives you the hability to decide whether your rocket will fly or not. The `Propellant` object always asks whether your rocket is ready or not and passes a `System.TriggerOperation` representing the trigger moment, and also its own state in case you need it (we'll see more on this further down when we discuss the rocket `Tank`).

On the trigger example above, `Propellant` would run something like this: `rocket.canTakeOff(TriggerOperation.BEFORE_INSERT, this);` and would move on only if this call returns `true`.

But what about the two methods (`flyOnBefore` and `flyOnAfter`)?
They come from respectively two subinterfaces of `Rocket`: `OnBeforeRocket` and `OnAfterRocket`.

![Rocket interface hierarchy](images/Rocket-Interfaces.png)

You see? That's where those methods come from.

As you can imagine, the class `OnInsertRocket`, used on the very first implementation example, has `canTakeOff` already implemented for you, giving the propeller green light to fire it off on `BEFORE_INSERT`. So that, if the trigger is for example `before insert, after insert, before update`, subclassing `OnInsertRocket`, would leave your rocket on the ground when the targeted record is being updated. Makes sense, right?

Conversely, when you directly implement the two interfaces, there's no Insert/Update/Delete/Undelete context involved. You're free to decide. Can you now see why `canTakeOff` receives a `TriggerOperation`?

