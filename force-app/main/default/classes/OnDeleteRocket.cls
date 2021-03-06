/**
 * Partial implementation of Delete rockets (before and after)
 * @author Jose Berardo Cunha
 * @since 30/04/2020
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public abstract class OnDeleteRocket implements OnBeforeRocket, OnAfterRocket {
  protected final List<SObject> oldList { get; private set; }
  protected final Map<ID, SObject> oldMap { get; private set; }

  public OnDeleteRocket() {
  }

  /**
   * Creates an OnDeleteRocket with a Set of Objects
   * @param oldList Set of SObjects expected to be passed (e.g. Trigger.old)
   */
  public OnDeleteRocket(List<SObject> oldList) {
    this.oldList = oldList;
  }

  /**
   * Creates an OnUpdateRocket with a Map of Id -> Objects
   * @param oldMap Map of Id -> SObject expecteds to be passed (e.g. Trigger.oldMap)
   */
  public OnDeleteRocket(Map<ID, SObject> oldMap) {
    this.oldMap = oldMap;
  }

  /**
   * Takes the TriggerOperation to fire off on `BEFORE_DELETE` and `AFTER_DELETE`
   * @param triggerWhen System.TriggerOperation
   * @param propellant Propellant object not in use here
   * @returns `Boolean`
   */
  public virtual Boolean canTakeOff(TriggerOperation triggerWhen, Propellant propellant) {
    return triggerWhen == TriggerOperation.BEFORE_DELETE ||
      triggerWhen == TriggerOperation.AFTER_DELETE;
  }

  /**
   * Dummy implementation of OnBeforeRocket
   */
  public virtual void flyOnBefore() {
  }

  /**
   * Dummy implementation of OnAfterRocket
   */
  public virtual void flyOnAfter() {
  }
}
